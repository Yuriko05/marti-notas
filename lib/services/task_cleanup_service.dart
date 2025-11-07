import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/firestore_collections.dart';
import '../models/task_model.dart';
import '../models/task_status.dart';

class TaskCleanupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Elimina automáticamente las tareas completadas después de 24 horas
  static Future<void> cleanupCompletedTasks() async {
    try {
      print('🧹 Iniciando limpieza de tareas completadas...');

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No hay usuario autenticado para limpieza');
        return;
      }

      // Calcular fecha límite (24 horas atrás)
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));

      print('⏰ Eliminando tareas completadas antes de: $cutoffTime');

      // Consultar tareas completadas que son más antiguas de 24 horas
      final completedTasksQuery = await _firestore
          .collection(FirestoreCollections.tasks)
          .where('status', isEqualTo: TaskStatus.completed.value)
          .where('completedAt', isLessThan: cutoffTime)
          .get();

      final tasksToDelete = completedTasksQuery.docs;
      print('📋 Encontradas ${tasksToDelete.length} tareas para eliminar');

      final userDoc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(currentUser.uid)
          .get();
      final isAdmin = userDoc.data()?['role'] == 'admin';

      // Eliminar cada tarea
      final batch = _firestore.batch();
      int deletedCount = 0;

      for (var taskDoc in tasksToDelete) {
        final taskData = taskDoc.data();
        final task = TaskModel.fromFirestore(taskData, taskDoc.id);

        if (task.assignedTo == currentUser.uid ||
            task.createdBy == currentUser.uid ||
            isAdmin) {
          batch.delete(taskDoc.reference);
          deletedCount++;

          print(
              '🗑️ Programada eliminación: ${task.title} (completada: ${task.completedAt})');
        }
      }

      // Ejecutar eliminación en lote
      if (deletedCount > 0) {
        await batch.commit();
        print('✅ Limpieza completada: $deletedCount tareas eliminadas');
      } else {
        print('ℹ️ No hay tareas que requieran limpieza');
      }
    } catch (e) {
      print('❌ Error durante la limpieza de tareas: $e');
    }
  }

  /// Elimina automáticamente las tareas completadas de un usuario específico
  static Future<void> cleanupUserCompletedTasks(String userId) async {
    try {
      print('🧹 Limpiando tareas completadas del usuario: $userId');

      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));

      // Consultar tareas completadas del usuario específico
      final userTasksQuery = await _firestore
          .collection(FirestoreCollections.tasks)
          .where('assignedTo', isEqualTo: userId)
          .where('status', isEqualTo: TaskStatus.completed.value)
          .where('completedAt', isLessThan: cutoffTime)
          .get();

      final batch = _firestore.batch();
      int deletedCount = 0;

      for (var taskDoc in userTasksQuery.docs) {
        batch.delete(taskDoc.reference);
        deletedCount++;
      }

      if (deletedCount > 0) {
        await batch.commit();
        print(
            '✅ Eliminadas $deletedCount tareas completadas del usuario $userId');
      }
    } catch (e) {
      print('❌ Error limpiando tareas del usuario: $e');
    }
  }

  /// Limpieza general para administradores (todas las tareas del sistema)
  static Future<void> adminCleanupAllCompletedTasks() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Verificar que el usuario sea admin
      final userDoc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(currentUser.uid)
          .get();
      if (userDoc.data()?['role'] != 'admin') {
        print('❌ Solo administradores pueden ejecutar limpieza general');
        return;
      }

      print('🧹 [ADMIN] Iniciando limpieza general del sistema...');

      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));

      final completedTasksQuery = await _firestore
          .collection(FirestoreCollections.tasks)
          .where('status', isEqualTo: TaskStatus.completed.value)
          .where('completedAt', isLessThan: cutoffTime)
          .get();

      final batch = _firestore.batch();
      int deletedCount = 0;

      for (var taskDoc in completedTasksQuery.docs) {
        batch.delete(taskDoc.reference);
        deletedCount++;
      }

      if (deletedCount > 0) {
        await batch.commit();
        print(
            '✅ [ADMIN] Limpieza general completada: $deletedCount tareas eliminadas del sistema');
      } else {
        print('ℹ️ [ADMIN] No hay tareas que requieran limpieza general');
      }
    } catch (e) {
      print('❌ Error en limpieza general de administrador: $e');
    }
  }

  /// Obtiene estadísticas de tareas que serían eliminadas
  static Future<Map<String, int>> getCleanupStatistics() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return {};

      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));

      // Contar tareas que serían eliminadas
      final completedTasksQuery = await _firestore
          .collection(FirestoreCollections.tasks)
          .where('status', isEqualTo: TaskStatus.completed.value)
          .where('completedAt', isLessThan: cutoffTime)
          .get();

      final userDoc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(currentUser.uid)
          .get();
      final isAdmin = userDoc.data()?['role'] == 'admin';

      int userTasks = 0;
      int assignedTasks = 0;
      int totalTasks = 0;

      for (var taskDoc in completedTasksQuery.docs) {
        final taskData = taskDoc.data();
        totalTasks++;

        if (taskData['assignedTo'] == currentUser.uid) {
          userTasks++;
        }
        if (taskData['createdBy'] == currentUser.uid) {
          assignedTasks++;
        }
      }

      return {
        'userTasks': userTasks,
        'assignedTasks': assignedTasks,
        'totalTasks': isAdmin ? totalTasks : userTasks + assignedTasks,
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas de limpieza: $e');
      return {};
    }
  }
}
