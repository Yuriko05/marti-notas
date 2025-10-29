import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

class TaskService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Marcar tarea como leída por el usuario
  static Future<bool> markTaskAsRead(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('tasks').doc(taskId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      AppLogger.success('Tarea $taskId marcada como leída',
          name: 'TaskService');
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

      await _firestore.collection('tasks').doc(taskId).update({
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
        'confirmedBy': user.uid,
      });

      AppLogger.success('Tarea $taskId confirmada por admin',
          name: 'TaskService');
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

      await _firestore.collection('tasks').doc(taskId).update({
        'status': 'pending', // Vuelve a pendiente
        'rejectionReason': reason,
        'completedAt': null, // Limpia la fecha de completado
      });

      AppLogger.success('Tarea $taskId rechazada por admin',
          name: 'TaskService');
      return true;
    } catch (e) {
      AppLogger.error('Error rechazando tarea', error: e, name: 'TaskService');
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

      await _firestore.collection('tasks').doc(taskId).update({
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
        'startedBy': user.uid,
      });

      AppLogger.success('Tarea $taskId iniciada por ${user.uid}',
          name: 'TaskService');
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

      await _firestore.collection('tasks').doc(taskId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'completedBy': user.uid,
      });

      AppLogger.success('Tarea $taskId completada por ${user.uid}',
          name: 'TaskService');
      return true;
    } catch (e) {
      AppLogger.error('Error completando tarea', error: e, name: 'TaskService');
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

      await _firestore.collection('tasks').doc(taskId).update(updateData);

      AppLogger.success('Estado de tarea $taskId revertido exitosamente',
          name: 'TaskService');
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

      AppLogger.success('Tarea personal creada: ${docRef.id}',
          name: 'TaskService');
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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc.data(), doc.id))
            .toList());
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

      await _firestore.collection('tasks').doc(taskId).update({
        'title': title,
        'description': description,
        'dueDate': Timestamp.fromDate(dueDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.success('Tarea personal actualizada: $taskId',
          name: 'TaskService');
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

      await _firestore.collection('tasks').doc(taskId).delete();

      AppLogger.success('Tarea personal eliminada: $taskId',
          name: 'TaskService');
      return true;
    } catch (e) {
      AppLogger.error('Error eliminando tarea personal',
          error: e, name: 'TaskService');
      return false;
    }
  }
}
