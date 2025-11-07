const {onDocumentUpdated} = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const {getFirestore} = require('../firebase');
const {sendToTokensWithRetries} = require('./helpers/sendToTokensWithRetries');

const COLLECTION_TASKS = 'tasks';
const COLLECTION_USERS = 'users';

const sendTaskReassignedNotification = onDocumentUpdated(
  `${COLLECTION_TASKS}/{taskId}`,
  async (event) => {
    const before = event.data.before?.data();
    const after = event.data.after?.data();
    if (!before || !after) return null;

    if (before.assignedTo !== after.assignedTo) {
      const db = getFirestore();
      logger.info('sendTaskReassignedNotification invoked', {
        taskId: event.params.taskId,
        before: {assignedTo: before.assignedTo},
        after: {assignedTo: after.assignedTo},
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
          logger.warn('No tokens found for reassigned user', {
            userId: after.assignedTo,
          });
          return null;
        }

        const adminDoc = await db.collection(COLLECTION_USERS)
          .doc(after.createdBy)
          .get();
        const adminData = adminDoc.data();
        const adminName = adminData?.name ?? 'Admin';

        const payload = {
          notification: {
            title: '📋 Tarea reasignada',
            body: `${adminName} te reasignó la tarea "${after.title}"`,
          },
          data: {
            taskId: event.params.taskId,
            type: 'task_reassigned',
            priority: after.priority || 'medium',
          },
        };

        return await sendToTokensWithRetries(
          db,
          payload,
          tokens,
          after.assignedTo,
        );
      } catch (error) {
        logger.error('Error sending task reassigned notification:', error);
        return null;
      }
    }
    return null;
  },
);

module.exports = {
  sendTaskReassignedNotification,
};
