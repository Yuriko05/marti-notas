const {onDocumentUpdated} = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const {getFirestore} = require('../firebase');
const {sendToTokensWithRetries} = require('./helpers/sendToTokensWithRetries');

const COLLECTION_TASKS = 'tasks';
const COLLECTION_USERS = 'users';

const sendTaskReviewApprovedNotification = onDocumentUpdated(
  `${COLLECTION_TASKS}/{taskId}`,
  async (event) => {
    const before = event.data.before?.data();
    const after = event.data.after?.data();
    if (!before || !after) return null;

    if (before.status === 'pending_review' && after.status === 'completed') {
      const db = getFirestore();
      logger.info('sendTaskReviewApprovedNotification invoked', {
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
          logger.warn('No tokens found for approved user', {
            userId: after.assignedTo,
          });
          return null;
        }

        const payload = {
          notification: {
            title: '✅ Tarea aprobada',
            body: `Tu tarea "${after.title}" fue aprobada por el admin`,
          },
          data: {
            taskId: event.params.taskId,
            type: 'task_review_approved',
          },
        };

        return await sendToTokensWithRetries(
          db,
          payload,
          tokens,
          after.assignedTo,
        );
      } catch (error) {
        logger.error('Error sending task review approved notification:', error);
        return null;
      }
    }
    return null;
  },
);

module.exports = {
  sendTaskReviewApprovedNotification,
};
