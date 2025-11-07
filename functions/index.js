/**
 * Cloud Functions para notificaciones push de tareas
 *
 * Funciones:
 * 1. sendTaskAssignedNotification
 * 2. sendTaskRejectedNotification
 * 3. sendTaskApprovedNotification
 * 4. createUser (HTTPS Callable)
 */

const {onDocumentCreated, onDocumentUpdated} =
  require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {getAuth} = require("firebase-admin/auth");
const logger = require("firebase-functions/logger");

// Inicializar Firebase Admin
initializeApp();

// Helper: enviar mensaje a tokens con retries y limpieza de tokens inválidos
async function sendToTokensWithRetries(db, payload, tokens, userId) {
  const messaging = getMessaging();
  const maxAttempts = 3;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      if (!tokens || tokens.length === 0) {
        return {success: false, error: "No tokens provided"};
      }

      if (tokens.length === 1) {
        const single = Object.assign({}, payload, {token: tokens[0]});
        const resp = await messaging.send(single);
        return {success: true, response: resp};
      } else {
        const multi = Object.assign({}, payload, {tokens});
        const resp = await messaging.sendMulticast(multi);

        // Eliminar tokens inválidos si los hay
        const badTokens = [];
        resp.responses.forEach((r, idx) => {
          if (!r.success) {
            const errCode = r.error && r.error.code ? r.error.code : null;
            if (errCode && (errCode.includes("registration-token-not-registered") || errCode.includes("invalid-registration-token") || errCode.includes("messaging/invalid-registration-token"))) {
              badTokens.push(tokens[idx]);
            }
          }
        });

        if (badTokens.length > 0 && userId) {
          try {
            await db.collection("users").doc(userId).update({
              fcmTokens: FieldValue.arrayRemove(...badTokens),
            });
          } catch (e) {
            logger.warn("Error eliminando tokens inválidos:", e);
          }
        }

        return {success: true, response: resp};
      }
    } catch (err) {
      logger.warn(`Attempt ${attempt} failed sending message: ${err}`);
      // espera exponencial
      await new Promise((r) => setTimeout(r, 300 * Math.pow(2, attempt)));
      if (attempt === maxAttempts) return {success: false, error: err};
    }
  }
}

/**
 * Cloud Function que escucha cuando se crea una nueva tarea
 * y envía una notificación push al usuario asignado
 */
exports.sendTaskAssignedNotification = onDocumentCreated(
    "tasks/{taskId}",
    async (event) => {
      try {
        const snapshot = event.data;
        const taskId = event.params.taskId;

        if (!snapshot) {
          logger.warn("No data associated with the event");
          return null;
        }

        const task = snapshot.data();
        logger.info("Nueva tarea creada:", {taskId, title: task.title});

        // Solo enviar notificación para tareas asignadas (no personales)
        if (task.isPersonal) {
          logger.info(`Tarea ${taskId} es personal, no se envía notificación`);
          return null;
        }

        // Obtener información del usuario asignado
        const db = getFirestore();
        const userDoc = await db.collection("users").doc(task.assignedTo).get();

        if (!userDoc.exists) {
          logger.warn(`Usuario ${task.assignedTo} no encontrado`);
          return null;
        }

        const userData = userDoc.data();
        // Soportamos fcmTokens (array) para múltiples dispositivos
        const tokens = (userData && userData.fcmTokens && Array.isArray(userData.fcmTokens)) ?
          userData.fcmTokens : (userData && userData.fcmToken ? [userData.fcmToken] : []);

        if (!tokens || tokens.length === 0) {
          logger.warn(`Usuario ${task.assignedTo} no tiene FCM tokens`);
          return null;
        }
        // Obtener información del admin que asignó
        const adminDoc =
          await db.collection("users").doc(task.createdBy).get();
        const adminData = adminDoc.exists ? adminDoc.data() : null;
        const adminName =
          adminData && adminData.name ? adminData.name : "Admin";

        // Construir el mensaje de notificación
        const messagePayload = {
          notification: {
            title: "📋 Nueva Tarea Asignada",
            body: `${adminName} te asignó: "${task.title}"`,
          },
          data: {
            taskId: taskId,
            type: "task_assigned",
            priority: task.priority || "medium",
          },
        };

        // Enviar la notificación (soportando múltiples tokens y retries)
        const messaging = getMessaging();
        const sendWithRetries = async (payload, targetTokens) => {
          const maxAttempts = 3;
          let attempt = 0;
          let lastError = null;

          while (attempt < maxAttempts) {
            try {
              if (targetTokens.length === 1) {
                const single = Object.assign({}, payload, {token: targetTokens[0]});
                const resp = await messaging.send(single);
                return {success: true, response: resp};
              } else {
                const multi = Object.assign({}, payload, {tokens: targetTokens});
                const resp = await messaging.sendMulticast(multi);
                return {success: true, response: resp};
              }
            } catch (err) {
              lastError = err;
              attempt++;
              logger.warn(`Intento ${attempt} falló al enviar notificación: ${err}`);
              // Espera exponencial antes de reintentar
              await new Promise((r) => setTimeout(r, 500 * Math.pow(2, attempt)));
            }
          }

          return {success: false, error: lastError};
        };

        // Usar helper que hace retries y limpieza de tokens inválidos
        const result = await sendToTokensWithRetries(db, messagePayload, tokens, task.assignedTo);

        if (!result.success) {
          logger.error("❌ No se pudo enviar la notificación después de reintentos:", result.error);
          return null;
        }

        logger.info("✅ Notificación enviada exitosamente (multicast/uno)");
        return result.response;
      } catch (error) {
        logger.error("❌ Error enviando notificación:", error);
        return null;
      }
    },
);

/**
 * Cloud Function para enviar notificación cuando una tarea es rechazada
 */
exports.sendTaskRejectedNotification = onDocumentUpdated(
    "tasks/{taskId}",
    async (event) => {
      try {
        const beforeSnapshot = event.data.before;
        const afterSnapshot = event.data.after;
        const taskId = event.params.taskId;

        if (!beforeSnapshot || !afterSnapshot) {
          logger.warn("No data associated with the event");
          return null;
        }

        // Debug: log before/after payloads to diagnose missed triggers
        try {
          logger.info('sendTaskRejectedNotification invoked', {taskId, before: beforeSnapshot.data(), after: afterSnapshot.data()});
        } catch (e) {
          logger.warn('Error al loggear payloads de rechazo', e);
        }

        const before = beforeSnapshot.data();
        const after = afterSnapshot.data();

        // Verificar si el estado cambió a 'rejected'
        if (before.status !== "rejected" && after.status === "rejected") {
          logger.info(`Tarea ${taskId} fue rechazada`);

          // Obtener FCM token del usuario
          const db = getFirestore();
          const userDoc =
            await db.collection("users").doc(after.assignedTo).get();

          if (!userDoc.exists) {
            logger.warn(`Usuario ${after.assignedTo} no encontrado`);
            return null;
          }

          const userData = userDoc.data();
          const tokens = (userData && userData.fcmTokens && Array.isArray(userData.fcmTokens)) ?
            userData.fcmTokens : (userData && userData.fcmToken ? [userData.fcmToken] : []);

          if (!tokens || tokens.length === 0) {
            logger.warn(`Usuario ${after.assignedTo} no tiene FCM tokens`);
            return null;
          }

          // Construir mensaje
          const messagePayload = {
            notification: {
              title: "❌ Tarea Rechazada",
              body: `La tarea "${after.title}" fue rechazada`,
            },
            data: {
              taskId: taskId,
              type: "task_rejected",
              reviewComment: after.reviewComment || "Sin comentarios",
            },
          };

          const result = await sendToTokensWithRetries(db, messagePayload, tokens, after.assignedTo);
          if (!result.success) {
            logger.error("❌ No se pudo enviar la notificación de rechazo:", result.error);
            return null;
          }

          logger.info(`✅ Notificación de rechazo enviada`);
          return result.response;
        }

        return null;
      } catch (error) {
        logger.error("❌ Error enviando notificación de rechazo:", error);
        return null;
      }
    },
);

/**
 * Cloud Function para enviar notificación cuando una tarea es aprobada
 */
exports.sendTaskApprovedNotification = onDocumentUpdated(
    "tasks/{taskId}",
    async (event) => {
      try {
        const beforeSnapshot = event.data.before;
        const afterSnapshot = event.data.after;
        const taskId = event.params.taskId;

        if (!beforeSnapshot || !afterSnapshot) {
          logger.warn("No data associated with the event");
          return null;
        }

        const before = beforeSnapshot.data();
        const after = afterSnapshot.data();

        // Verificar si el estado cambió a 'confirmed'
        if (before.status !== "confirmed" && after.status === "confirmed") {
          logger.info(`Tarea ${taskId} fue aprobada`);

          // Obtener FCM token del usuario
          const db = getFirestore();
          const userDoc =
            await db.collection("users").doc(after.assignedTo).get();

          if (!userDoc.exists) {
            logger.warn(`Usuario ${after.assignedTo} no encontrado`);
            return null;
          }

          const userData = userDoc.data();
          const tokens = (userData && userData.fcmTokens && Array.isArray(userData.fcmTokens)) ?
            userData.fcmTokens : (userData && userData.fcmToken ? [userData.fcmToken] : []);

          if (!tokens || tokens.length === 0) {
            logger.warn(`Usuario ${after.assignedTo} no tiene FCM tokens`);
            return null;
          }

          const messagePayload = {
            notification: {
              title: "✅ Tarea Aprobada",
              body: `La tarea "${after.title}" fue aprobada por el admin`,
            },
            data: {
              taskId: taskId,
              type: "task_approved",
              reviewComment: after.reviewComment || "",
            },
          };

          const result = await sendToTokensWithRetries(db, messagePayload, tokens, after.assignedTo);
          if (!result.success) {
            logger.error("❌ No se pudo enviar la notificación de aprobación:", result.error);
            return null;
          }

          logger.info(`✅ Notificación de aprobación enviada`);
          return result.response;
        }

        return null;
      } catch (error) {
        logger.error("❌ Error enviando notificación de aprobación:", error);
        return null;
      }
    },
);

/**
 * Cloud Function HTTPS Callable
 * Crear usuarios sin cerrar sesión del admin
 *
 * Parámetros:
 * - name: Nombre del usuario
 * - password: Contraseña del usuario
 * - role: Rol del usuario ('normal' o 'admin')
 *
 * Retorna:
 * - uid: ID del usuario creado
 * - email: Email generado para el usuario
 */
exports.createUser = onCall(async (request) => {
  try {
    // 1. Verificar que el usuario está autenticado
    if (!request.auth) {
      throw new HttpsError(
          "unauthenticated",
          "Usuario no autenticado",
      );
    }

    const callerId = request.auth.uid;
    logger.info(`👤 Usuario ${callerId} solicitando crear nuevo usuario`);

    // 2. Verificar que el usuario que llama es admin
    const db = getFirestore();
    const callerDoc = await db.collection("users").doc(callerId).get();

    if (!callerDoc.exists || callerDoc.data().role !== "admin") {
      throw new HttpsError(
          "permission-denied",
          "No tienes permisos de administrador",
      );
    }

    // 3. Validar parámetros
    const {name, password, role} = request.data;

    if (!name || typeof name !== "string" || name.trim().length === 0) {
      throw new HttpsError("invalid-argument", "El nombre es requerido");
    }

    if (!password || typeof password !== "string" || password.length < 6) {
      throw new HttpsError(
          "invalid-argument",
          "La contraseña debe tener al menos 6 caracteres",
      );
    }

    if (!role || !["normal", "admin"].includes(role)) {
      throw new HttpsError(
          "invalid-argument",
          "El rol debe ser 'normal' o 'admin'",
      );
    }

    const trimmedName = name.trim();

    // 4. Verificar que el nombre no esté en uso
    const existingUserQuery = await db
        .collection("users")
        .where("name", "==", trimmedName)
        .limit(1)
        .get();

    if (!existingUserQuery.empty) {
      throw new HttpsError(
          "already-exists",
          `Ya existe un usuario con el nombre: ${trimmedName}`,
      );
    }

    // 5. Generar email fake
    const normalizedName = trimmedName.toLowerCase().replace(/\s+/g, "");
    const fakeEmail = `${normalizedName}@gmail.com`;
    logger.info(`📧 Email generado: ${fakeEmail}`);

    // 6. Crear usuario en Firebase Authentication usando Admin SDK
    const auth = getAuth();
    const userRecord = await auth.createUser({
      email: fakeEmail,
      password: password,
      displayName: trimmedName,
    });

    logger.info(`✅ Usuario creado en Auth: ${userRecord.uid}`);

    // 7. Crear perfil en Firestore
    const now = new Date();
    const userProfile = {
      uid: userRecord.uid,
      email: fakeEmail,
      name: trimmedName,
      role: role,
      username: trimmedName.toLowerCase().replace(/\s+/g, ""),
      hasPassword: true,
      createdAt: now,
      lastLogin: now,
      // Soportamos múltiples tokens por usuario
      fcmTokens: [],
      fcmTokensUpdatedAt: null,
    };

    await db.collection("users").doc(userRecord.uid).set(userProfile);

    logger.info(`✅ Perfil creado en Firestore para: ${trimmedName}`);

    // 8. Retornar información del usuario creado
    return {
      success: true,
      uid: userRecord.uid,
      email: fakeEmail,
      name: trimmedName,
      role: role,
      message: `Usuario ${trimmedName} creado exitosamente`,
    };
  } catch (error) {
    logger.error("❌ Error creando usuario:", error);

    // Si el error ya es un HttpsError, re-lanzarlo
    if (error instanceof HttpsError) {
      throw error;
    }

    // Manejar errores específicos de Firebase Auth
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError(
          "already-exists",
          "El email ya está en uso",
      );
    }

    // Error genérico
    throw new HttpsError(
        "internal",
        `Error al crear usuario: ${error.message}`,
    );
  }
});

