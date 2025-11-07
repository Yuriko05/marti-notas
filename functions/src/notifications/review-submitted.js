const {onDocumentUpdated} = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const {getFirestore} = require('../firebase');
const {sendToTokensWithRetries} = require('./helpers/sendToTokensWithRetries');

const COLLECTION_TASKS = 'tasks';
const COLLECTION_USERS = 'users';

const sendTaskReviewSubmittedNotification = onDocumentUpdated(
  `${COLLECTION_TASKS}/{taskId}`,
  async (event) => {
    const before = event.data.before?.data();
    const after = event.data.after?.data();
    if (!before || !after) return null;

    if (before.status !== 'pending_review' && after.status === 'pending_review') {
      const db = getFirestore();
      logger.info('sendTaskReviewSubmittedNotification invoked', {
        taskId: event.params.taskId,
        before: {status: before.status},
        after: {status: after.status},
      });

      try {
        const adminsSnap = await db.collection(COLLECTION_USERS)
          .where('role', '==', 'admin')
          .get();
        const tokens = [];
        adminsSnap.forEach((doc) => {
          const data = doc.data();
          if (Array.isArray(data.fcmTokens)) tokens.push(...data.fcmTokens);
          else if (data.fcmToken) tokens.push(data.fcmToken);
        });

        if (!tokens.length) {
          logger.warn('No admin tokens found for review submission');
          return null;
        }

        const userSnap = await db.collection(COLLECTION_USERS)
          .doc(after.assignedTo)
          .get();
        const userData = userSnap.data();
        const userName = userData?.name ?? 'Un usuario';

        const payload = {
          notification: {
            title: '📥 Tarea enviada para revisión',
            body: `${userName} envió la tarea "${after.title}" para revisión`,
          },
          data: {
            taskId: event.params.taskId,
            type: 'task_review_submitted',
          },
        };

        return await sendToTokensWithRetries(db, payload, tokens);
      } catch (error) {
        logger.error('Error sending task review submitted notification:', error);
        return null;
      }
    }
    return null;
  },
);

module.exports = {
  sendTaskReviewSubmittedNotification,
};
