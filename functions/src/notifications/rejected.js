const {onDocumentUpdated} = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const {getFirestore} = require('../firebase');
const {sendToTokensWithRetries} = require('./helpers/sendToTokensWithRetries');

const COLLECTION_TASKS = 'tasks';
const COLLECTION_USERS = 'users';

const sendTaskRejectedNotification = onDocumentUpdated(
  `${COLLECTION_TASKS}/{taskId}`,
  async (event) => {
    try {
      const beforeSnapshot = event.data.before;
      const afterSnapshot = event.data.after;
      const taskId = event.params.taskId;

      if (!beforeSnapshot || !afterSnapshot) {
        logger.warn('No data associated with the event');
        return null;
      }

      try {
        logger.info('sendTaskRejectedNotification invoked', {
          taskId,
          before: beforeSnapshot.data(),
          after: afterSnapshot.data(),
        });
      } catch (loggingError) {
        logger.warn('Error al loggear payloads de rechazo', loggingError);
      }

      const before = beforeSnapshot.data();
      const after = afterSnapshot.data();

      if (before.status !== 'rejected' && after.status === 'rejected') {
        logger.info(`Tarea ${taskId} fue rechazada`);

        const db = getFirestore();
        const userDoc = await db.collection(COLLECTION_USERS)
          .doc(after.assignedTo)
          .get();

        if (!userDoc.exists) {
          logger.warn(`Usuario ${after.assignedTo} no encontrado`);
          return null;
        }

        const userData = userDoc.data();
        const tokens = Array.isArray(userData?.fcmTokens)
          ? userData.fcmTokens
          : (userData?.fcmToken ? [userData.fcmToken] : []);

        if (!tokens || tokens.length === 0) {
          logger.warn(`Usuario ${after.assignedTo} no tiene FCM tokens`);
          return null;
        }

        const messagePayload = {
          notification: {
            title: '❌ Tarea Rechazada',
            body: `La tarea "${after.title}" fue rechazada`,
          },
          data: {
            taskId,
            type: 'task_rejected',
            reviewComment: after.reviewComment || 'Sin comentarios',
          },
        };

        const result = await sendToTokensWithRetries(
          db,
          messagePayload,
          tokens,
          after.assignedTo,
        );

        if (!result.success) {
          logger.error('❌ No se pudo enviar la notificación de rechazo:', result.error);
          return null;
        }

        logger.info('✅ Notificación de rechazo enviada');
        return result.response;
      }

      return null;
    } catch (error) {
      logger.error('❌ Error enviando notificación de rechazo:', error);
      return null;
    }
  },
);

module.exports = {
  sendTaskRejectedNotification,
};
