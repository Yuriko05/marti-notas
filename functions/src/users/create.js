const {onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const {getFirestore, getAuth} = require("../firebase");

const COLLECTION_USERS = "users";

const createUser = onCall(async (request) => {
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Usuario no autenticado");
    }

    const callerId = request.auth.uid;
    logger.info(`👤 Usuario ${callerId} solicitando crear nuevo usuario`);

    const db = getFirestore();
    const callerDoc = await db.collection(COLLECTION_USERS).doc(callerId).get();

    if (!callerDoc.exists || callerDoc.data().role !== "admin") {
      throw new HttpsError("permission-denied", "No tienes permisos de administrador");
    }

    const {name, password, role} = request.data;

    if (!name || typeof name !== "string" || name.trim().length === 0) {
      throw new HttpsError("invalid-argument", "El nombre es requerido");
    }

    if (!password || typeof password !== "string" || password.length < 6) {
      throw new HttpsError("invalid-argument", "La contraseña debe tener al menos 6 caracteres");
    }

    if (!role || !["normal", "admin"].includes(role)) {
      throw new HttpsError("invalid-argument", "El rol debe ser 'normal' o 'admin'");
    }

    const trimmedName = name.trim();

    const existingUserQuery = await db
        .collection(COLLECTION_USERS)
        .where("name", "==", trimmedName)
        .limit(1)
        .get();

    if (!existingUserQuery.empty) {
      throw new HttpsError("already-exists", `Ya existe un usuario con el nombre: ${trimmedName}`);
    }

    const normalizedName = trimmedName.toLowerCase().replace(/\s+/g, "");
    const fakeEmail = `${normalizedName}@gmail.com`;
    logger.info(`📧 Email generado: ${fakeEmail}`);

    const auth = getAuth();
    const userRecord = await auth.createUser({
      email: fakeEmail,
      password: password,
      displayName: trimmedName,
    });

    logger.info(`✅ Usuario creado en Auth: ${userRecord.uid}`);

    const now = new Date();
    const userProfile = {
      uid: userRecord.uid,
      email: fakeEmail,
      name: trimmedName,
      role: role,
      username: normalizedName,
      hasPassword: true,
      createdAt: now,
      lastLogin: now,
      fcmTokens: [],
      fcmTokensUpdatedAt: null,
    };

    await db.collection(COLLECTION_USERS).doc(userRecord.uid).set(userProfile);

    logger.info(`✅ Perfil creado en Firestore para: ${trimmedName}`);

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

    if (error instanceof HttpsError) {
      throw error;
    }

    if (error.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "El email ya está en uso");
    }

    throw new HttpsError("internal", `Error al crear usuario: ${error.message}`);
  }
});

module.exports = {
  createUser,
};
