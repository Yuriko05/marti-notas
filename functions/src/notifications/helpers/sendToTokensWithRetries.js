const { getMessaging, getFirestore, FieldValue } = require("../../firebase");
const logger = require("firebase-functions/logger");

/**
 * Helper que intenta enviar notificaciones a múltiples tokens
 * realizando reintentos y limpiando tokens inválidos en Firestore.
 * Se mantiene el mismo comportamiento utilizado en el monolito original.
 */
async function sendToTokensWithRetries(payload, tokens, userId) {
  const messaging = getMessaging();
  const db = getFirestore(); // ✅ solo una vez aquí arriba
  const maxAttempts = 3;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      if (!tokens || tokens.length === 0) {
        return { success: false, error: "No tokens provided" };
      }

      if (tokens.length === 1) {
        const single = { ...payload, token: tokens[0] };
        const resp = await messaging.send(single);
        return { success: true, response: resp };
      }

      const multi = { ...payload, tokens };
      const resp = await messaging.sendMulticast(multi);

      const badTokens = [];
      resp.responses.forEach((r, idx) => {
        if (!r.success) {
          const errCode = r.error?.code;
          if (
            errCode &&
            (errCode.includes("registration-token-not-registered") ||
              errCode.includes("invalid-registration-token") ||
              errCode.includes("messaging/invalid-registration-token"))
          ) {
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

      return { success: true, response: resp };
    } catch (err) {
      logger.warn(`Attempt ${attempt} failed sending message: ${err}`);
      await new Promise((r) => setTimeout(r, 300 * Math.pow(2, attempt)));
      if (attempt === maxAttempts) return { success: false, error: err };
    }
  }
}

module.exports = { sendToTokensWithRetries };
