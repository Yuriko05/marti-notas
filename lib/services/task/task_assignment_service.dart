import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/firestore_collections.dart';
import '../../models/task_model.dart';
import '../../models/task_status.dart';
import '../../utils/logger.dart';
import '../history_service.dart';
import '../notification_service.dart';

/// Maneja la creación y mantenimiento de tareas asignadas,
/// incluidas las tareas personales del usuario.
class TaskAssignmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  const TaskAssignmentService._();

  /// Crea una tarea personal para el usuario autenticado.
  static Future<String?> createPersonalTask({
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.warning('No hay usuario autenticado',
            name: 'TaskAssignmentService');
        return null;
      }

      final taskData = {
        'title': title,
        'description': description,
        'dueDate': Timestamp.fromDate(dueDate),
        'assignedTo': user.uid,
        'createdBy': user.uid,
        'isPersonal': true,
        'status': TaskStatus.pending.value,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection(FirestoreCollections.tasks)
          .add(taskData);

      try {
        await HistoryService.recordEvent(
          taskId: docRef.id,
          action: 'create_personal',
          actorUid: user.uid,
          actorRole: null,
          payload: {'after': taskData},
        );
      } catch (_) {}

      final task = TaskModel.fromFirestore(taskData, docRef.id);
      await NotificationService.schedulePersonalTaskNotifications(task: task);

      AppLogger.success('Tarea personal creada: ${docRef.id}',
          name: 'TaskAssignmentService');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Error creando tarea personal',
          error: e, name: 'TaskAssignmentService');
      return null;
    }
  }

  /// Devuelve un stream con las tareas de un usuario por estado.
  static Stream<List<TaskModel>> getUserTasksByStatus(
      String userId, TaskStatus status) {
    return _firestore
        .collection(FirestoreCollections.tasks)
        .where('assignedTo', isEqualTo: userId)
        .where('status', isEqualTo: status.value)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Devuelve todas las tareas asignadas a un usuario.
  static Stream<List<TaskModel>> getUserTasks(String userId) {
    return _firestore
        .collection(FirestoreCollections.tasks)
        .where('assignedTo', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc.data(), doc.id))
          .toList();

      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    });
  }

  /// Actualiza el contenido de una tarea personal.
  static Future<bool> updatePersonalTask({
    required String taskId,
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final taskDoc = await _firestore
          .collection(FirestoreCollections.tasks)
          .doc(taskId)
          .get();
      if (!taskDoc.exists) return false;

      final taskData = taskDoc.data();
      if (taskData?['assignedTo'] != user.uid || taskData?['isPersonal'] != true) {
        AppLogger.warning('Usuario no autorizado para actualizar esta tarea',
            name: 'TaskAssignmentService');
        return false;
      }

      final taskRef =
          _firestore.collection(FirestoreCollections.tasks).doc(taskId);
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

      AppLogger.success('Tarea personal actualizada: $taskId',
          name: 'TaskAssignmentService');
      return true;
    } catch (e) {
      AppLogger.error('Error actualizando tarea personal',
          error: e, name: 'TaskAssignmentService');
      return false;
    }
  }

  /// Elimina una tarea personal del usuario actual.
  static Future<bool> deletePersonalTask(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final taskDoc = await _firestore
          .collection(FirestoreCollections.tasks)
          .doc(taskId)
          .get();
      if (!taskDoc.exists) return false;

      final taskData = taskDoc.data();
      if (taskData?['assignedTo'] != user.uid || taskData?['isPersonal'] != true) {
        AppLogger.warning('Usuario no autorizado para eliminar esta tarea',
            name: 'TaskAssignmentService');
        return false;
      }

      final taskRef =
          _firestore.collection(FirestoreCollections.tasks).doc(taskId);
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

      AppLogger.success('Tarea personal eliminada: $taskId',
          name: 'TaskAssignmentService');
      return true;
    } catch (e) {
      AppLogger.error('Error eliminando tarea personal',
          error: e, name: 'TaskAssignmentService');
      return false;
    }
  }
}
