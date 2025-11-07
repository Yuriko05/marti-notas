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

// Helper: enviar mensaje a tokens con retries y limpieza de tokens invÃ¡lidos
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

        // Eliminar tokens invÃ¡lidos si los hay
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
            logger.warn("Error eliminando tokens invÃ¡lidos:", e);
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
 * y envÃ­a una notificaciÃ³n push al usuario asignado
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

        // Solo enviar notificaciÃ³n para tareas asignadas (no personales)
        if (task.isPersonal) {
          logger.info(`Tarea ${taskId} es personal, no se envÃ­a notificaciÃ³n`);
          return null;
        }

        // Obtener informaciÃ³n del usuario asignado
        const db = getFirestore();
        const userDoc = await db.collection("users").doc(task.assignedTo).get();

        if (!userDoc.exists) {
          logger.warn(`Usuario ${task.assignedTo} no encontrado`);
          return null;
        }

        const userData = userDoc.data();
        // Soportamos fcmTokens (array) para mÃºltiples dispositivos
        const tokens = (userData && userData.fcmTokens && Array.isArray(userData.fcmTokens)) ?
          userData.fcmTokens : (userData && userData.fcmToken ? [userData.fcmToken] : []);

        if (!tokens || tokens.length === 0) {
          logger.warn(`Usuario ${task.assignedTo} no tiene FCM tokens`);
          return null;
        }
        // Obtener informaciÃ³n del admin que asignÃ³
        const adminDoc =
          await db.collection("users").doc(task.createdBy).get();
        const adminData = adminDoc.exists ? adminDoc.data() : null;
        const adminName =
          adminData && adminData.name ? adminData.name : "Admin";

        // Construir el mensaje de notificaciÃ³n
        const messagePayload = {
          notification: {
            title: "ðŸ“‹ Nueva Tarea Asignada",
            body: `${adminName} te asignÃ³: "${task.title}"`,
          },
          data: {
            taskId: taskId,
            type: "task_assigned",
            priority: task.priority || "medium",
          },
        };

        // Enviar la notificaciÃ³n (soportando mÃºltiples tokens y retries)
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
              logger.warn(`Intento ${attempt} fallÃ³ al enviar notificaciÃ³n: ${err}`);
              // Espera exponencial antes de reintentar
              await new Promise((r) => setTimeout(r, 500 * Math.pow(2, attempt)));
            }
          }

          return {success: false, error: lastError};
        };

        // Usar helper que hace retries y limpieza de tokens invÃ¡lidos
        const result = await sendToTokensWithRetries(db, messagePayload, tokens, task.assignedTo);

        if (!result.success) {
          logger.error("âŒ No se pudo enviar la notificaciÃ³n despuÃ©s de reintentos:", result.error);
          return null;
        }

        logger.info("âœ… NotificaciÃ³n enviada exitosamente (multicast/uno)");
        return result.response;
      } catch (error) {
        logger.error("âŒ Error enviando notificaciÃ³n:", error);
        return null;
      }
    },
);

/**
 * Cloud Function para enviar notificaciÃ³n cuando una tarea es rechazada
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

        // Verificar si el estado cambiÃ³ a 'rejected'
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
              title: "âŒ Tarea Rechazada",
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
            logger.error("âŒ No se pudo enviar la notificaciÃ³n de rechazo:", result.error);
            return null;
          }

          logger.info(`âœ… NotificaciÃ³n de rechazo enviada`);
          return result.response;
        }

        return null;
      } catch (error) {
        logger.error("âŒ Error enviando notificaciÃ³n de rechazo:", error);
        return null;
      }
    },
);

/**
 * Cloud Function para enviar notificaciÃ³n cuando una tarea es aprobada
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

        // Verificar si el estado cambiÃ³ a 'confirmed'
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
              title: "âœ… Tarea Aprobada",
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
            logger.error("âŒ No se pudo enviar la notificaciÃ³n de aprobaciÃ³n:", result.error);
            return null;
          }

          logger.info(`âœ… NotificaciÃ³n de aprobaciÃ³n enviada`);
          return result.response;
        }

        return null;
      } catch (error) {
        logger.error("âŒ Error enviando notificaciÃ³n de aprobaciÃ³n:", error);
        return null;
      }
    },
);

/**
 * Cloud Function HTTPS Callable
 * Crear usuarios sin cerrar sesiÃ³n del admin
 *
 * ParÃ¡metros:
 * - name: Nombre del usuario
 * - password: ContraseÃ±a del usuario
 * - role: Rol del usuario ('normal' o 'admin')
 *
 * Retorna:
 * - uid: ID del usuario creado
 * - email: Email generado para el usuario
 */
exports.createUser = onCall(async (request) => {
  try {
    // 1. Verificar que el usuario estÃ¡ autenticado
    if (!request.auth) {
      throw new HttpsError(
          "unauthenticated",
          "Usuario no autenticado",
      );
    }

    const callerId = request.auth.uid;
    logger.info(`ðŸ‘¤ Usuario ${callerId} solicitando crear nuevo usuario`);

    // 2. Verificar que el usuario que llama es admin
    const db = getFirestore();
    const callerDoc = await db.collection("users").doc(callerId).get();

    if (!callerDoc.exists || callerDoc.data().role !== "admin") {
      throw new HttpsError(
          "permission-denied",
          "No tienes permisos de administrador",
      );
    }

    // 3. Validar parÃ¡metros
    const {name, password, role} = request.data;

    if (!name || typeof name !== "string" || name.trim().length === 0) {
      throw new HttpsError("invalid-argument", "El nombre es requerido");
    }

    if (!password || typeof password !== "string" || password.length < 6) {
      throw new HttpsError(
          "invalid-argument",
          "La contraseÃ±a debe tener al menos 6 caracteres",
      );
    }

    if (!role || !["normal", "admin"].includes(role)) {
      throw new HttpsError(
          "invalid-argument",
          "El rol debe ser 'normal' o 'admin'",
      );
    }

    const trimmedName = name.trim();

    // 4. Verificar que el nombre no estÃ© en uso
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
    logger.info(`ðŸ“§ Email generado: ${fakeEmail}`);

    // 6. Crear usuario en Firebase Authentication usando Admin SDK
    const auth = getAuth();
    const userRecord = await auth.createUser({
      email: fakeEmail,
      password: password,
      displayName: trimmedName,
    });

    logger.info(`âœ… Usuario creado en Auth: ${userRecord.uid}`);

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
      // Soportamos mÃºltiples tokens por usuario
      fcmTokens: [],
      fcmTokensUpdatedAt: null,
    };

    await db.collection("users").doc(userRecord.uid).set(userProfile);

    logger.info(`âœ… Perfil creado en Firestore para: ${trimmedName}`);

    // 8. Retornar informaciÃ³n del usuario creado
    return {
      success: true,
      uid: userRecord.uid,
      email: fakeEmail,
      name: trimmedName,
      role: role,
      message: `Usuario ${trimmedName} creado exitosamente`,
    };
  } catch (error) {
    logger.error("âŒ Error creando usuario:", error);

    // Si el error ya es un HttpsError, re-lanzarlo
    if (error instanceof HttpsError) {
      throw error;
    }

    // Manejar errores especÃ­ficos de Firebase Auth
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError(
          "already-exists",
          "El email ya estÃ¡ en uso",
      );
    }

    // Error genÃ©rico
    throw new HttpsError(
        "internal",
        `Error al crear usuario: ${error.message}`,
    );
  }
});

// ðŸ”„ NotificaciÃ³n de reasignaciÃ³n de tarea
exports.sendTaskReassignedNotification = onDocumentUpdated(
    "tasks/{taskId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
      if (!before || !after) return null;

      // Detectar cambio de asignaciÃ³n
      if (before.assignedTo !== after.assignedTo) {
        const db = getFirestore();
        logger.info("sendTaskReassignedNotification invoked", {
          taskId: event.params.taskId,
          before: {assignedTo: before.assignedTo},
          after: {assignedTo: after.assignedTo},
        });

        try {
          // Obtener tokens del nuevo usuario
          const userDoc = await db.collection("users").doc(after.assignedTo).get();
          const userData = userDoc.data();
          const tokens = (userData && Array.isArray(userData.fcmTokens))
            ? userData.fcmTokens
            : (userData && userData.fcmToken ? [userData.fcmToken] : []);

          if (!tokens.length) {
            logger.warn("No tokens found for reassigned user", {userId: after.assignedTo});
            return null;
          }

          const adminDoc = await db.collection("users").doc(after.createdBy).get();
          const adminData = adminDoc.data();
          const adminName = (adminData && adminData.name) ? adminData.name : "Admin";

          const payload = {
            notification: {
              title: "ðŸ“‹ Tarea reasignada",
              body: `${adminName} te reasignÃ³ la tarea "${after.title}"`,
            },
            data: {
              taskId: event.params.taskId,
              type: "task_reassigned",
              priority: after.priority || "medium",
            },
          };

          return await sendToTokensWithRetries(db, payload, tokens, after.assignedTo);
        } catch (error) {
          logger.error("Error sending task reassigned notification:", error);
          return null;
        }
      }
      return null;
    },
);

// ðŸ“¥ NotificaciÃ³n de envÃ­o a revisiÃ³n (usuario â†’ admin)
exports.sendTaskReviewSubmittedNotification = onDocumentUpdated(
    "tasks/{taskId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
      if (!before || !after) return null;

      // Cambio de estado a 'pending_review'
      if (before.status !== "pending_review" && after.status === "pending_review") {
        const db = getFirestore();
        logger.info("sendTaskReviewSubmittedNotification invoked", {
          taskId: event.params.taskId,
          before: {status: before.status},
          after: {status: after.status},
        });

        try {
          // Obtener todos los admin
          const adminsSnap = await db.collection("users").where("role", "==", "admin").get();
          const tokens = [];
          adminsSnap.forEach((doc) => {
            const data = doc.data();
            if (Array.isArray(data.fcmTokens)) tokens.push(...data.fcmTokens);
            else if (data.fcmToken) tokens.push(data.fcmToken);
          });

          if (!tokens.length) {
            logger.warn("No admin tokens found for review submission");
            return null;
          }

          // Mensaje a admins
          const userSnap = await db.collection("users").doc(after.assignedTo).get();
          const userData = userSnap.data();
          const userName = (userData && userData.name) ? userData.name : "Un usuario";
          const payload = {
            notification: {
              title: "ðŸ“¥ Tarea enviada para revisiÃ³n",
              body: `${userName} enviÃ³ la tarea "${after.title}" para revisiÃ³n`,
            },
            data: {
              taskId: event.params.taskId,
              type: "task_review_submitted",
            },
          };

          return await sendToTokensWithRetries(db, payload, tokens);
        } catch (error) {
          logger.error("Error sending task review submitted notification:", error);
          return null;
        }
      }
      return null;
    },
);

// âœ… NotificaciÃ³n de aprobaciÃ³n tras revisiÃ³n
exports.sendTaskReviewApprovedNotification = onDocumentUpdated(
    "tasks/{taskId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
      if (!before || !after) return null;

      if (before.status === "pending_review" && after.status === "completed") {
        const db = getFirestore();
        logger.info("sendTaskReviewApprovedNotification invoked", {
          taskId: event.params.taskId,
          before: {status: before.status},
          after: {status: after.status},
        });

        try {
          const userDoc = await db.collection("users").doc(after.assignedTo).get();
          const userData = userDoc.data();
          const tokens = (userData && Array.isArray(userData.fcmTokens))
            ? userData.fcmTokens
            : (userData && userData.fcmToken ? [userData.fcmToken] : []);

          if (!tokens.length) {
            logger.warn("No tokens found for approved user", {userId: after.assignedTo});
            return null;
          }

          const payload = {
            notification: {
              title: "âœ… Tarea aprobada",
              body: `Tu tarea "${after.title}" fue aprobada por el admin`,
            },
            data: {
              taskId: event.params.taskId,
              type: "task_review_approved",
            },
          };

          return await sendToTokensWithRetries(db, payload, tokens, after.assignedTo);
        } catch (error) {
          logger.error("Error sending task review approved notification:", error);
          return null;
        }
      }
      return null;
    },
);

// âŒ NotificaciÃ³n de rechazo en revisiÃ³n
exports.sendTaskReviewRejectedNotification = onDocumentUpdated(
    "tasks/{taskId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
      if (!before || !after) return null;

      if (before.status === "pending_review" && after.status === "in_progress") {
        const db = getFirestore();
        logger.info("sendTaskReviewRejectedNotification invoked", {
          taskId: event.params.taskId,
          before: {status: before.status},
          after: {status: after.status},
        });

        try {
          const userDoc = await db.collection("users").doc(after.assignedTo).get();
          const userData = userDoc.data();
          const tokens = (userData && Array.isArray(userData.fcmTokens))
            ? userData.fcmTokens
            : (userData && userData.fcmToken ? [userData.fcmToken] : []);

          if (!tokens.length) {
            logger.warn("No tokens found for rejected review user", {userId: after.assignedTo});
            return null;
          }

          const payload = {
            notification: {
              title: "âŒ RevisiÃ³n rechazada",
              body: `Tu tarea "${after.title}" fue rechazada; revisa los comentarios del admin`,
            },
            data: {
              taskId: event.params.taskId,
              type: "task_review_rejected",
            },
          };

          return await sendToTokensWithRetries(db, payload, tokens, after.assignedTo);
        } catch (error) {
          logger.error("Error sending task review rejected notification:", error);
          return null;
        }
      }
      return null;
    },
);

// ðŸ”’ FunciÃ³n para garantizar tokens Ãºnicos entre usuarios
exports.ensureUniqueFcmTokens = onDocumentUpdated(
    "users/{userId}",
    async (event) => {
      const after = event.data.after.data();
      if (!after || !Array.isArray(after.fcmTokens) || after.fcmTokens.length === 0) {
        return null;
      }

      const db = getFirestore();
      const currentUserId = event.params.userId;
      const newTokens = after.fcmTokens;

      logger.info("ensureUniqueFcmTokens invoked", {
        userId: currentUserId,
        tokensCount: newTokens.length,
      });

      try {
        // Buscar otros usuarios que tengan alguno de estos tokens
        const usersQuery = await db.collection("users")
            .where("fcmTokens", "array-contains-any", newTokens)
            .get();

        const batch = db.batch();
        let conflictsFound = 0;

        usersQuery.forEach((doc) => {
          const userId = doc.id;
          const userData = doc.data();

          // No procesar el usuario actual
          if (userId === currentUserId) return;

          if (Array.isArray(userData.fcmTokens)) {
            // Encontrar tokens duplicados
            const duplicatedTokens = userData.fcmTokens.filter((token) =>
              newTokens.includes(token),
            );

            if (duplicatedTokens.length > 0) {
              conflictsFound++;
              logger.info("Removing duplicated tokens", {
                fromUser: userId,
                tokens: duplicatedTokens,
                movingToUser: currentUserId,
              });

              // Remover tokens duplicados del otro usuario
              const updatedTokens = userData.fcmTokens.filter((token) =>
                !duplicatedTokens.includes(token),
              );

              batch.update(doc.ref, {
                fcmTokens: updatedTokens,
                fcmTokensUpdatedAt: FieldValue.serverTimestamp(),
              });
            }
          }
        });

        if (conflictsFound > 0) {
          await batch.commit();
          logger.info("Token conflicts resolved", {
            conflictsResolved: conflictsFound,
            newOwner: currentUserId,
          });
        }

        return null;
      } catch (error) {
        logger.error("Error ensuring unique FCM tokens:", error);
        return null;
      }
    },
);

