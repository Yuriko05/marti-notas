const {onDocumentUpdated} = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const {getFirestore, FieldValue} = require('../firebase');

const COLLECTION_USERS = 'users';

/**
 * Garantiza que cada token FCM pertenezca a un único usuario.
 * Conserva la implementación original, ahora como módulo reutilizable.
 */
const ensureUniqueFcmTokens = onDocumentUpdated(
  `${COLLECTION_USERS}/{userId}`,
  async (event) => {
    const after = event.data.after?.data();
    if (!after || !Array.isArray(after.fcmTokens) || after.fcmTokens.length === 0) {
      return null;
    }

    const db = getFirestore();
    const currentUserId = event.params.userId;
    const newTokens = after.fcmTokens;

    logger.info('ensureUniqueFcmTokens invoked', {
      userId: currentUserId,
      tokensCount: newTokens.length,
    });

    try {
      const usersQuery = await db.collection(COLLECTION_USERS)
        .where('fcmTokens', 'array-contains-any', newTokens)
        .get();

      const batch = db.batch();
      let conflictsFound = 0;

      usersQuery.forEach((doc) => {
        const userId = doc.id;
        const userData = doc.data();
        if (userId === currentUserId) return;

        if (Array.isArray(userData.fcmTokens)) {
          const duplicatedTokens = userData.fcmTokens.filter((token) =>
            newTokens.includes(token),
          );

          if (duplicatedTokens.length > 0) {
            conflictsFound++;
            logger.info('Removing duplicated tokens', {
              fromUser: userId,
              tokens: duplicatedTokens,
              movingToUser: currentUserId,
            });

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
        logger.info('Token conflicts resolved', {
          conflictsResolved: conflictsFound,
          newOwner: currentUserId,
        });
      }

      return null;
    } catch (error) {
      logger.error('Error ensuring unique FCM tokens:', error);
      return null;
    }
  },
);

module.exports = {
  ensureUniqueFcmTokens,
};
