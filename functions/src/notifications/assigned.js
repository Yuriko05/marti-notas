const {onDocumentCreated} = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const {getFirestore} = require('../firebase');
const {sendToTokensWithRetries} = require('./helpers/sendToTokensWithRetries');

const COLLECTION_TASKS = 'tasks';
const COLLECTION_USERS = 'users';

const sendTaskAssignedNotification = onDocumentCreated(
  `${COLLECTION_TASKS}/{taskId}`,
  async (event) => {
    try {
      const snapshot = event.data;
      const taskId = event.params.taskId;

      if (!snapshot) {
        logger.warn('No data associated with the event');
        return null;
      }

      const task = snapshot.data();
      logger.info('Nueva tarea creada:', {taskId, title: task.title});

      if (task.isPersonal) {
        logger.info(`Tarea ${taskId} es personal, no se envía notificación`);
        return null;
      }

      const db = getFirestore();
      const userDoc = await db.collection(COLLECTION_USERS)
        .doc(task.assignedTo)
        .get();

      if (!userDoc.exists) {
        logger.warn(`Usuario ${task.assignedTo} no encontrado`);
        return null;
      }

      const userData = userDoc.data();
      const tokens = Array.isArray(userData?.fcmTokens)
        ? userData.fcmTokens
        : (userData?.fcmToken ? [userData.fcmToken] : []);

      if (!tokens || tokens.length === 0) {
        logger.warn(`Usuario ${task.assignedTo} no tiene FCM tokens`);
        return null;
      }

      const adminDoc = await db.collection(COLLECTION_USERS)
        .doc(task.createdBy)
        .get();
      const adminData = adminDoc.exists ? adminDoc.data() : null;
      const adminName = adminData?.name ?? 'Admin';

      const messagePayload = {
        notification: {
          title: '📋 Nueva Tarea Asignada',
          body: `${adminName} te asignó: "${task.title}"`,
        },
        data: {
          taskId,
          type: 'task_assigned',
          priority: task.priority || 'medium',
        },
      };

      const result = await sendToTokensWithRetries(
        db,
        messagePayload,
        tokens,
        task.assignedTo,
      );

      if (!result.success) {
        logger.error('❌ No se pudo enviar la notificación después de reintentos:', result.error);
        return null;
      }

      logger.info('✅ Notificación enviada exitosamente (multicast/uno)');
      return result.response;
    } catch (error) {
      logger.error('❌ Error enviando notificación:', error);
      return null;
    }
  },
);

module.exports = {
  sendTaskAssignedNotification,
};
