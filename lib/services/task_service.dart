import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';
import 'completed_tasks_service.dart';
import 'history_service.dart';
import 'notification_service.dart';

class TaskService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Marcar tarea como leída por el usuario
  static Future<bool> markTaskAsRead(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final taskRef = _firestore.collection('tasks').doc(taskId);

      // Obtener estado previo
      final prevSnap = await taskRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;

      await taskRef.update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
        'readBy': user.uid,
      });

      // Obtener estado posterior
      final afterSnap = await taskRef.get();
      final afterData = afterSnap.exists ? afterSnap.data() : null;

      // Obtener role del actor si existe
      String? actorRole;
      try {
        final actorDoc = await _firestore.collection('users').doc(user.uid).get();
        final actorData = actorDoc.exists ? actorDoc.data() : null;
        actorRole = actorData != null ? (actorData['role'] as String?) : null;
      } catch (_) {
        actorRole = null;
      }

      // Registrar evento de history
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
        AppLogger.warning('No se pudo escribir history para read: $e', name: 'TaskService');
      }

      AppLogger.success('Tarea $taskId marcada como leída', name: 'TaskService');
      return true;
    } catch (e) {
      AppLogger.error('Error marcando tarea como leída',
          error: e, name: 'TaskService');
      return false;
    }
  }

  /// Admin confirma tarea completada
  static Future<bool> confirmTask(String taskId, {String? notes}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Verificar que el usuario es admin
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists || userDoc.data()?['role'] != 'admin') {
        AppLogger.warning('Solo administradores pueden confirmar tareas',
            name: 'TaskService');
        return false;
      }

      final taskRef = _firestore.collection('tasks').doc(taskId);

      // Obtener previo
      final prevSnap = await taskRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;

      await taskRef.update({
        'status': 'confirmed',
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

      // 🔔 NO enviar notificación local aquí
      // Las notificaciones push se envían automáticamente por Cloud Function
      // (sendTaskApprovedNotification se activa cuando status cambia a 'confirmed')

      AppLogger.success('Tarea $taskId confirmada por admin', name: 'TaskService');
      return true;
    } catch (e) {
      AppLogger.error('Error confirmando tarea', error: e, name: 'TaskService');
      return false;
    }
  }

  /// Admin rechaza tarea completada
  static Future<bool> rejectTask(String taskId, String reason) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Verificar que el usuario es admin
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists || userDoc.data()?['role'] != 'admin') {
        AppLogger.warning('Solo administradores pueden rechazar tareas',
            name: 'TaskService');
        return false;
      }

      final taskRef = _firestore.collection('tasks').doc(taskId);
      final prevSnap = await taskRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;

      await taskRef.update({
        'status': 'rejected',
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

      // 🔔 NO enviar notificación local aquí
      // Las notificaciones push se envían automáticamente por Cloud Function
      // (sendTaskRejectedNotification se activa cuando status cambia a 'rejected')

      AppLogger.success('Tarea $taskId rechazada por admin', name: 'TaskService');
      return true;
    } catch (e) {
      AppLogger.error('Error rechazando tarea', error: e, name: 'TaskService');
      return false;
    }
  }

  /// Admin aprueba tarea en revisión (nuevo flujo con evidencias)
  static Future<bool> approveTaskReview({
    required String taskId,
    String? reviewComment,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Verificar que el usuario es admin
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists || userDoc.data()?['role'] != 'admin') {
        AppLogger.warning('Solo administradores pueden aprobar tareas',
            name: 'TaskService');
        return false;
      }

      final taskRef = _firestore.collection('tasks').doc(taskId);
      final prevSnap = await taskRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;

      await taskRef.update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'confirmedAt': FieldValue.serverTimestamp(),
        'confirmedBy': user.uid,
        'reviewComment': reviewComment,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      final afterSnap = await taskRef.get();
      final afterData = afterSnap.exists ? afterSnap.data() : null;

      await HistoryService.recordEvent(
        taskId: taskId,
        action: 'approve_review',
        actorUid: user.uid,
        actorRole: userDoc.data()?['role'] as String?,
        payload: {
          'before': prevData,
          'after': afterData,
          'reviewComment': reviewComment,
        },
      );

      // Registrar tarea completada en historial
      try {
        final completedTask = afterData != null
            ? TaskModel.fromFirestore(afterData, taskId)
            : null;
        if (completedTask != null) {
          await CompletedTasksService.recordCompletedTask(completedTask);
        }
      } catch (e) {
        AppLogger.warning('Error guardando en historial de completadas: $e',
            name: 'TaskService');
      }

      AppLogger.success('Tarea $taskId aprobada por admin', name: 'TaskService');
      return true;
    } catch (e) {
      AppLogger.error('Error aprobando tarea', error: e, name: 'TaskService');
      return false;
    }
  }

  /// Admin rechaza tarea en revisión (nuevo flujo con evidencias)
  static Future<bool> rejectTaskReview({
    required String taskId,
    required String reason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Verificar que el usuario es admin
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists || userDoc.data()?['role'] != 'admin') {
        AppLogger.warning('Solo administradores pueden rechazar tareas',
            name: 'TaskService');
        return false;
      }

      final taskRef = _firestore.collection('tasks').doc(taskId);
      final prevSnap = await taskRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;

      await taskRef.update({
        'status': 'in_progress', // Vuelve a in_progress para que el usuario corrija
        'rejectionReason': reason,
        'reviewComment': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      final afterSnap = await taskRef.get();
      final afterData = afterSnap.exists ? afterSnap.data() : null;

      await HistoryService.recordEvent(
        taskId: taskId,
        action: 'reject_review',
        actorUid: user.uid,
        actorRole: userDoc.data()?['role'] as String?,
        payload: {'before': prevData, 'after': afterData, 'reason': reason},
      );

      AppLogger.success('Tarea $taskId rechazada en revisión por admin', name: 'TaskService');
      return true;
    } catch (e) {
      AppLogger.error('Error rechazando tarea en revisión', error: e, name: 'TaskService');
      return false;
    }
  }

  /// Obtener tareas agrupadas por usuario (para admin)
  static Future<Map<UserModel, List<TaskModel>>> getTasksGroupedByUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      // Verificar que es admin
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists || userDoc.data()?['role'] != 'admin') {
        return {};
      }

      // Obtener todos los usuarios (no admins)
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'normal')
          .get();

      final Map<UserModel, List<TaskModel>> groupedTasks = {};

      for (var userDoc in usersSnapshot.docs) {
        final userModel = UserModel.fromFirestore(userDoc.data(), userDoc.id);

        // Obtener tareas del usuario
        final tasksSnapshot = await _firestore
            .collection('tasks')
            .where('assignedTo', isEqualTo: userDoc.id)
            .where('isPersonal', isEqualTo: false)
            .orderBy('createdAt', descending: true)
            .get();

        final tasks = tasksSnapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc.data(), doc.id))
            .toList();

        if (tasks.isNotEmpty) {
          groupedTasks[userModel] = tasks;
        }
      }

      return groupedTasks;
    } catch (e) {
      AppLogger.error('Error obteniendo tareas agrupadas',
          error: e, name: 'TaskService');
      return {};
    }
  }

  /// Obtener estadísticas de tareas pendientes de confirmación
  static Future<Map<String, int>> getConfirmationStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final completedSnapshot = await _firestore
          .collection('tasks')
          .where('status', isEqualTo: 'completed')
          .where('createdBy', isEqualTo: user.uid)
          .get();

      final confirmedSnapshot = await _firestore
          .collection('tasks')
          .where('status', isEqualTo: 'confirmed')
          .where('createdBy', isEqualTo: user.uid)
          .get();

      final rejectedSnapshot = await _firestore
          .collection('tasks')
          .where('status', isEqualTo: 'rejected')
          .where('createdBy', isEqualTo: user.uid)
          .get();

      return {
        'pending_confirmation': completedSnapshot.size,
        'confirmed': confirmedSnapshot.size,
        'rejected': rejectedSnapshot.size,
      };
    } catch (e) {
      AppLogger.error('Error obteniendo estadísticas de confirmación',
          error: e, name: 'TaskService');
      return {};
    }
  }

  /// Stream de tareas que necesitan confirmación
  static Stream<List<TaskModel>> getTasksNeedingConfirmation() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('tasks')
        .where('status', isEqualTo: 'completed')
        .where('createdBy', isEqualTo: user.uid)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Usuario inicia la tarea (marca como en progreso)
  static Future<bool> startTask(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final taskRef = _firestore.collection('tasks').doc(taskId);
      final prevSnap = await taskRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;

      await taskRef.update({
        'status': 'in_progress',
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

      AppLogger.success('Tarea $taskId iniciada por ${user.uid}', name: 'TaskService');
      return true;
    } catch (e) {
      AppLogger.error('Error iniciando tarea', error: e, name: 'TaskService');
      return false;
    }
  }

  /// Usuario marca tarea como completada
  static Future<bool> completeTask(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final taskRef = _firestore.collection('tasks').doc(taskId);
      final prevSnap = await taskRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;
      final task = prevData != null 
          ? TaskModel.fromFirestore(prevData, taskId)
          : null;

      await taskRef.update({
        'status': 'completed',
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

      // Registrar tarea completada en historial
      try {
        final completedTask = afterData != null
            ? TaskModel.fromFirestore(afterData, taskId)
            : null;
        if (completedTask != null) {
          await CompletedTasksService.recordCompletedTask(completedTask);
        }
      } catch (e) {
        AppLogger.warning('Error guardando en historial de completadas: $e',
            name: 'TaskService');
      }

      // 🔔 Notificación y cancelar notificaciones programadas
      if (task != null) {
        // Cancelar notificaciones pendientes
        await NotificationService.cancelTaskNotifications(taskId);
        
        // Si es tarea personal, mostrar notificación de felicitación
        if (task.isPersonal) {
          await NotificationService.showPersonalTaskCompletedNotification(
            taskTitle: task.title,
            taskId: taskId,
          );
        }
      }

      AppLogger.success('Tarea $taskId completada por ${user.uid}', name: 'TaskService');
      return true;
    } catch (e) {
      AppLogger.error('Error completando tarea', error: e, name: 'TaskService');
      return false;
    }
  }

  /// Usuario envía tarea para revisión con evidencias (nuevo flujo)
  static Future<bool> submitTaskForReview({
    required String taskId,
    String? comment,
    List<String>? links,
    List<String>? attachments,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final taskRef = _firestore.collection('tasks').doc(taskId);
      final prevSnap = await taskRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;

      await taskRef.update({
        'status': 'pending_review',
        'completionComment': comment,
        'links': links ?? [],
        'attachmentUrls': attachments ?? [],
        'submittedAt': FieldValue.serverTimestamp(),
      });

      final afterSnap = await taskRef.get();
      final afterData = afterSnap.exists ? afterSnap.data() : null;

      await HistoryService.recordEvent(
        taskId: taskId,
        action: 'submit_for_review',
        actorUid: user.uid,
        actorRole: null,
        payload: {
          'before': prevData,
          'after': afterData,
          'comment': comment,
          'links': links,
          'attachments': attachments,
        },
      );

      AppLogger.success('Tarea $taskId enviada para revisión por ${user.uid}', name: 'TaskService');
      return true;
    } catch (e) {
      AppLogger.error('Error enviando tarea para revisión', error: e, name: 'TaskService');
      return false;
    }
  }

  /// Revierte el estado de una tarea al estado anterior
  /// in_progress -> pending
  /// completed -> in_progress
  static Future<bool> revertTaskStatus(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Obtener estado actual
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) return false;

      final currentStatus = taskDoc.data()?['status'] as String?;
      if (currentStatus == null) return false;

      // Determinar nuevo estado y datos a actualizar
      Map<String, dynamic> updateData = {};

      if (currentStatus == 'in_progress') {
        updateData = {
          'status': 'pending',
          'startedAt': FieldValue.delete(),
          'startedBy': FieldValue.delete(),
        };
        AppLogger.info('Revirtiendo tarea $taskId: in_progress -> pending',
            name: 'TaskService');
      } else if (currentStatus == 'completed') {
        updateData = {
          'status': 'in_progress',
          'completedAt': FieldValue.delete(),
          'completedBy': FieldValue.delete(),
        };
        AppLogger.info('Revirtiendo tarea $taskId: completed -> in_progress',
            name: 'TaskService');
      } else {
        // Si está en pending, no hay nada que revertir
        AppLogger.warning('Tarea $taskId ya está en estado pending',
            name: 'TaskService');
        return false;
      }

      final taskRef = _firestore.collection('tasks').doc(taskId);
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

      AppLogger.success('Estado de tarea $taskId revertido exitosamente', name: 'TaskService');
      return true;
    } catch (e) {
      AppLogger.error('Error revirtiendo estado de tarea',
          error: e, name: 'TaskService');
      return false;
    }
  }

  /// Crear tarea personal (usuario crea su propia tarea)
  static Future<String?> createPersonalTask({
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.warning('No hay usuario autenticado', name: 'TaskService');
        return null;
      }

      final taskData = {
        'title': title,
        'description': description,
        'dueDate': Timestamp.fromDate(dueDate),
        'assignedTo': user.uid,
        'createdBy': user.uid,
        'isPersonal': true,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('tasks').add(taskData);

      try {
        await HistoryService.recordEvent(
          taskId: docRef.id,
          action: 'create_personal',
          actorUid: user.uid,
          actorRole: null,
          payload: {'after': taskData},
        );
      } catch (_) {}

      // 🔔 Programar notificaciones para la tarea personal
      final task = TaskModel.fromFirestore(taskData, docRef.id);
      await NotificationService.schedulePersonalTaskNotifications(task: task);

      AppLogger.success('Tarea personal creada: ${docRef.id}', name: 'TaskService');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Error creando tarea personal',
          error: e, name: 'TaskService');
      return null;
    }
  }

  /// Stream de tareas del usuario por estado
  static Stream<List<TaskModel>> getUserTasksByStatus(
      String userId, String status) {
    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .where('status', isEqualTo: status)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Stream de todas las tareas del usuario
  static Stream<List<TaskModel>> getUserTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Ordenar en memoria para evitar necesitar índice compuesto
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return tasks;
    });
  }

  /// Actualizar tarea personal
  static Future<bool> updatePersonalTask({
    required String taskId,
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Verificar que la tarea pertenece al usuario
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) return false;

      final taskData = taskDoc.data();
      if (taskData?['assignedTo'] != user.uid ||
          taskData?['isPersonal'] != true) {
        AppLogger.warning('Usuario no autorizado para actualizar esta tarea',
            name: 'TaskService');
        return false;
      }

      final taskRef = _firestore.collection('tasks').doc(taskId);
      final prevSnap = await taskRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;

      await taskRef.update({
        'title': title,
        'description': description,
        'dueDate': Timestamp.fromDate(dueDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final afterSnap = await taskRef.get();
      final afterData = afterSnap.exists ? afterSnap.data() : null;

      await HistoryService.recordEvent(
        taskId: taskId,
        action: 'update_personal',
        actorUid: user.uid,
        actorRole: null,
        payload: {'before': prevData, 'after': afterData},
      );

      AppLogger.success('Tarea personal actualizada: $taskId', name: 'TaskService');
      return true;
    } catch (e) {
      AppLogger.error('Error actualizando tarea personal',
          error: e, name: 'TaskService');
      return false;
    }
  }

  /// Eliminar tarea personal
  static Future<bool> deletePersonalTask(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Verificar que la tarea pertenece al usuario
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) return false;

      final taskData = taskDoc.data();
      if (taskData?['assignedTo'] != user.uid ||
          taskData?['isPersonal'] != true) {
        AppLogger.warning('Usuario no autorizado para eliminar esta tarea',
            name: 'TaskService');
        return false;
      }

      final taskRef = _firestore.collection('tasks').doc(taskId);
      final prevSnap = await taskRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;

      try {
        await HistoryService.recordEvent(
          taskId: taskId,
          action: 'delete_personal',
          actorUid: user.uid,
          actorRole: null,
          payload: {'before': prevData, 'after': null},
        );
      } catch (_) {}

      await taskRef.delete();

      AppLogger.success('Tarea personal eliminada: $taskId', name: 'TaskService');
      return true;
    } catch (e) {
      AppLogger.error('Error eliminando tarea personal',
          error: e, name: 'TaskService');
      return false;
    }
  }
}
