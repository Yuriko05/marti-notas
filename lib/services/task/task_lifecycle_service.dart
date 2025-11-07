import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/firestore_collections.dart';
import '../../models/task_model.dart';
import '../../models/task_status.dart';
import '../../utils/logger.dart';
import '../history_service.dart';
import '../notification_service.dart';

/// Encapsula las operaciones relacionadas con el ciclo de vida de una tarea
/// (lectura, inicio, completado, confirmación, rechazo y reversión).
class TaskLifecycleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  const TaskLifecycleService._();

  /// Marca la tarea como leída por el usuario actual y registra el evento.
  static Future<bool> markTaskAsRead(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final taskRef =
          _firestore.collection(FirestoreCollections.tasks).doc(taskId);

      final prevSnap = await taskRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;

      await taskRef.update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
        'readBy': user.uid,
      });

      final afterSnap = await taskRef.get();
      final afterData = afterSnap.exists ? afterSnap.data() : null;

      String? actorRole;
      try {
        final actorDoc = await _firestore
            .collection(FirestoreCollections.users)
            .doc(user.uid)
            .get();
        final actorData = actorDoc.exists ? actorDoc.data() : null;
        actorRole = actorData != null ? (actorData['role'] as String?) : null;
      } catch (_) {
        actorRole = null;
      }

      try {
        await HistoryService.recordEvent(
          taskId: taskId,
          action: 'read',
          actorUid: user.uid,
          actorRole: actorRole,
          payload: {
            'before': prevData,
            'after': afterData,
          },
        );
      } catch (e) {
        AppLogger.warning('No se pudo escribir history para read: $e',
            name: 'TaskLifecycleService');
      }

      AppLogger.success('Tarea $taskId marcada como leída',
          name: 'TaskLifecycleService');
      return true;
    } catch (e) {
      AppLogger.error('Error marcando tarea como leída',
          error: e, name: 'TaskLifecycleService');
      return false;
    }
  }

  /// Confirma una tarea completada por un administrador.
  static Future<bool> confirmTask(String taskId, {String? notes}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .get();
      if (!userDoc.exists || userDoc.data()?['role'] != 'admin') {
        AppLogger.warning('Solo administradores pueden confirmar tareas',
            name: 'TaskLifecycleService');
        return false;
      }

      final taskRef =
          _firestore.collection(FirestoreCollections.tasks).doc(taskId);

      final prevSnap = await taskRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;

      await taskRef.update({
        'status': TaskStatus.confirmed.value,
        'confirmedAt': FieldValue.serverTimestamp(),
        'confirmedBy': user.uid,
      });

      final afterSnap = await taskRef.get();
      final afterData = afterSnap.exists ? afterSnap.data() : null;

      await HistoryService.recordEvent(
        taskId: taskId,
        action: 'confirm',
        actorUid: user.uid,
        actorRole: userDoc.data()?['role'] as String?,
        payload: {'before': prevData, 'after': afterData, 'notes': notes},
      );

      AppLogger.success('Tarea $taskId confirmada por admin',
          name: 'TaskLifecycleService');
      return true;
    } catch (e) {
      AppLogger.error('Error confirmando tarea',
          error: e, name: 'TaskLifecycleService');
      return false;
    }
  }

  /// Rechaza una tarea completada por un administrador con motivo documentado.
  static Future<bool> rejectTask(String taskId, String reason) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .get();
      if (!userDoc.exists || userDoc.data()?['role'] != 'admin') {
        AppLogger.warning('Solo administradores pueden rechazar tareas',
            name: 'TaskLifecycleService');
        return false;
      }

      final taskRef =
          _firestore.collection(FirestoreCollections.tasks).doc(taskId);
      final prevSnap = await taskRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;

      await taskRef.update({
        'status': TaskStatus.rejected.value,
        'rejectionReason': reason,
        'reviewComment': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      final afterSnap = await taskRef.get();
      final afterData = afterSnap.exists ? afterSnap.data() : null;

      await HistoryService.recordEvent(
        taskId: taskId,
        action: 'reject',
        actorUid: user.uid,
        actorRole: userDoc.data()?['role'] as String?,
        payload: {'before': prevData, 'after': afterData, 'reason': reason},
      );

      AppLogger.success('Tarea $taskId rechazada por admin',
          name: 'TaskLifecycleService');
      return true;
    } catch (e) {
      AppLogger.error('Error rechazando tarea',
          error: e, name: 'TaskLifecycleService');
      return false;
    }
  }

  /// Inicia una tarea por parte del usuario asignado.
  static Future<bool> startTask(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final taskRef =
          _firestore.collection(FirestoreCollections.tasks).doc(taskId);
      final prevSnap = await taskRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;

      await taskRef.update({
        'status': TaskStatus.inProgress.value,
        'startedAt': FieldValue.serverTimestamp(),
        'startedBy': user.uid,
      });

      final afterSnap = await taskRef.get();
      final afterData = afterSnap.exists ? afterSnap.data() : null;

      await HistoryService.recordEvent(
        taskId: taskId,
        action: 'start',
        actorUid: user.uid,
        actorRole: null,
        payload: {'before': prevData, 'after': afterData},
      );

      AppLogger.success('Tarea $taskId iniciada por ${user.uid}',
          name: 'TaskLifecycleService');
      return true;
    } catch (e) {
      AppLogger.error('Error iniciando tarea',
          error: e, name: 'TaskLifecycleService');
      return false;
    }
  }

  /// Completa una tarea y ejecuta las acciones asociadas (history/notificaciones).
  static Future<bool> completeTask(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final taskRef =
          _firestore.collection(FirestoreCollections.tasks).doc(taskId);
      final prevSnap = await taskRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;
      final task = prevData != null
          ? TaskModel.fromFirestore(prevData, taskId)
          : null;

      await taskRef.update({
        'status': TaskStatus.completed.value,
        'completedAt': FieldValue.serverTimestamp(),
        'completedBy': user.uid,
      });

      final afterSnap = await taskRef.get();
      final afterData = afterSnap.exists ? afterSnap.data() : null;

      await HistoryService.recordEvent(
        taskId: taskId,
        action: 'complete',
        actorUid: user.uid,
        actorRole: null,
        payload: {'before': prevData, 'after': afterData},
      );

      if (task != null) {
        await NotificationService.cancelTaskNotifications(taskId);

        if (task.isPersonal) {
          await NotificationService.showPersonalTaskCompletedNotification(
            taskTitle: task.title,
            taskId: taskId,
          );
        }
      }

      AppLogger.success('Tarea $taskId completada por ${user.uid}',
          name: 'TaskLifecycleService');
      return true;
    } catch (e) {
      AppLogger.error('Error completando tarea',
          error: e, name: 'TaskLifecycleService');
      return false;
    }
  }

  /// Revierte la tarea a un estado anterior (pending o in_progress).
  static Future<bool> revertTaskStatus(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final taskDoc = await _firestore
          .collection(FirestoreCollections.tasks)
          .doc(taskId)
          .get();
      if (!taskDoc.exists) return false;

      final currentStatus =
          taskStatusFromString(taskDoc.data()?['status'] as String?);

      Map<String, dynamic> updateData = {};

      if (currentStatus == TaskStatus.inProgress) {
        updateData = {
          'status': TaskStatus.pending.value,
          'startedAt': FieldValue.delete(),
          'startedBy': FieldValue.delete(),
        };
        AppLogger.info('Revirtiendo tarea $taskId: in_progress -> pending',
            name: 'TaskLifecycleService');
      } else if (currentStatus == TaskStatus.completed) {
        updateData = {
          'status': TaskStatus.inProgress.value,
          'completedAt': FieldValue.delete(),
          'completedBy': FieldValue.delete(),
        };
        AppLogger.info('Revirtiendo tarea $taskId: completed -> in_progress',
            name: 'TaskLifecycleService');
      } else {
        AppLogger.warning('Tarea $taskId ya está en estado pending',
            name: 'TaskLifecycleService');
        return false;
      }

      final taskRef =
          _firestore.collection(FirestoreCollections.tasks).doc(taskId);
      final prevSnap = await taskRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;

      await taskRef.update(updateData);

      final afterSnap = await taskRef.get();
      final afterData = afterSnap.exists ? afterSnap.data() : null;

      await HistoryService.recordEvent(
        taskId: taskId,
        action: 'revert',
        actorUid: user.uid,
        actorRole: null,
        payload: {'before': prevData, 'after': afterData},
      );

      AppLogger.success('Estado de tarea $taskId revertido exitosamente',
          name: 'TaskLifecycleService');
      return true;
    } catch (e) {
      AppLogger.error('Error revirtiendo estado de tarea',
          error: e, name: 'TaskLifecycleService');
      return false;
    }
  }
}
