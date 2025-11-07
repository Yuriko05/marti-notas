const {onDocumentUpdated} = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const {getFirestore} = require('../firebase');
const {sendToTokensWithRetries} = require('./helpers/sendToTokensWithRetries');

const COLLECTION_TASKS = 'tasks';
const COLLECTION_USERS = 'users';

const sendTaskReviewRejectedNotification = onDocumentUpdated(
  `${COLLECTION_TASKS}/{taskId}`,
  async (event) => {
    const before = event.data.before?.data();
    const after = event.data.after?.data();
    if (!before || !after) return null;

    if (before.status === 'pending_review' && after.status === 'in_progress') {
      const db = getFirestore();
      logger.info('sendTaskReviewRejectedNotification invoked', {
        taskId: event.params.taskId,
        before: {status: before.status},
        after: {status: after.status},
      });

      try {
        const userDoc = await db.collection(COLLECTION_USERS)
          .doc(after.assignedTo)
          .get();
        const userData = userDoc.data();
        const tokens = Array.isArray(userData?.fcmTokens)
          ? userData.fcmTokens
          : (userData?.fcmToken ? [userData.fcmToken] : []);

        if (!tokens.length) {
          logger.warn('No tokens found for rejected review user', {
            userId: after.assignedTo,
          });
          return null;
        }

        const payload = {
          notification: {
            title: '❌ Revisión rechazada',
            body: `Tu tarea "${after.title}" fue rechazada; revisa los comentarios del admin`,
          },
          data: {
            taskId: event.params.taskId,
            type: 'task_review_rejected',
          },
        };

        return await sendToTokensWithRetries(
          db,
          payload,
          tokens,
          after.assignedTo,
        );
      } catch (error) {
        logger.error('Error sending task review rejected notification:', error);
        return null;
      }
    }
    return null;
  },
);

module.exports = {
  sendTaskReviewRejectedNotification,
};
