import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/firestore_collections.dart';
import '../../models/task_model.dart';
import '../../models/task_status.dart';
import '../../models/user_model.dart';
import '../../utils/logger.dart';

/// Genera estadísticas y agrupaciones relacionadas con las tareas.
class TaskStatsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  const TaskStatsService._();

  /// Retorna un mapa de usuarios con sus tareas asociadas (solo admin).
  static Future<Map<UserModel, List<TaskModel>>> getTasksGroupedByUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final userDoc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .get();
      if (!userDoc.exists || userDoc.data()?['role'] != 'admin') {
        return {};
      }

      final usersSnapshot = await _firestore
          .collection(FirestoreCollections.users)
          .where('role', isEqualTo: 'normal')
          .get();

      final Map<UserModel, List<TaskModel>> groupedTasks = {};

      for (final userDoc in usersSnapshot.docs) {
        final userModel = UserModel.fromFirestore(userDoc.data(), userDoc.id);

        final tasksSnapshot = await _firestore
            .collection(FirestoreCollections.tasks)
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
          error: e, name: 'TaskStatsService');
      return {};
    }
  }

  /// Calcula estadísticas de confirmación de tareas creadas por el usuario.
  static Future<Map<String, int>> getConfirmationStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final completedSnapshot = await _firestore
          .collection(FirestoreCollections.tasks)
          .where('status', isEqualTo: TaskStatus.completed.value)
          .where('createdBy', isEqualTo: user.uid)
          .get();

      final confirmedSnapshot = await _firestore
          .collection(FirestoreCollections.tasks)
          .where('status', isEqualTo: TaskStatus.confirmed.value)
          .where('createdBy', isEqualTo: user.uid)
          .get();

      final rejectedSnapshot = await _firestore
          .collection(FirestoreCollections.tasks)
          .where('status', isEqualTo: TaskStatus.rejected.value)
          .where('createdBy', isEqualTo: user.uid)
          .get();

      return {
        'pending_confirmation': completedSnapshot.size,
        'confirmed': confirmedSnapshot.size,
        'rejected': rejectedSnapshot.size,
      };
    } catch (e) {
      AppLogger.error('Error obteniendo estadísticas de confirmación',
          error: e, name: 'TaskStatsService');
      return {};
    }
  }

  /// Stream con las tareas que requieren confirmación para el usuario actual.
  static Stream<List<TaskModel>> getTasksNeedingConfirmation() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection(FirestoreCollections.tasks)
        .where('status', isEqualTo: TaskStatus.completed.value)
        .where('createdBy', isEqualTo: user.uid)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}
