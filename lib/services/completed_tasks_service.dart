import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

/// Guarda tareas completadas en `completed_tasks` y expone streams para listarlas.
class CompletedTasksService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Guarda una tarea completada para consultarla luego, incluso si se borra de `tasks`.
  static Future<void> recordCompletedTask(TaskModel task) async {
    final data = {
      'taskId': task.id,
      'title': task.title,
      'description': task.description,
      'dueDate': Timestamp.fromDate(task.dueDate),
      'assignedTo': task.assignedTo,
      'createdBy': task.createdBy,
      'isPersonal': task.isPersonal,
      'status': task.status,
      'priority': task.priority,
      'createdAt': Timestamp.fromDate(task.createdAt),
      'completedAt': task.completedAt != null
          ? Timestamp.fromDate(task.completedAt!)
          : FieldValue.serverTimestamp(),
      'confirmedAt': task.confirmedAt != null
          ? Timestamp.fromDate(task.confirmedAt!)
          : null,
      'confirmedBy': task.confirmedBy,
      'reviewComment': task.reviewComment,
      'completionComment': task.completionComment,
    };
    await _firestore.collection('completed_tasks').doc(task.id).set(data);
  }

  /// Devuelve en tiempo real las tareas completadas de un usuario, ordenadas por `completedAt`.
  static Stream<List<TaskModel>> getUserCompletedTasks(String userId) {
    return _firestore
        .collection('completed_tasks')
        .where('assignedTo', isEqualTo: userId)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return TaskModel(
                id: data['taskId'] ?? doc.id,
                title: data['title'] ?? '',
                description: data['description'] ?? '',
                dueDate: (data['dueDate'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                assignedTo: data['assignedTo'] ?? '',
                createdBy: data['createdBy'] ?? '',
                isPersonal: data['isPersonal'] ?? false,
                status: data['status'] ?? 'completed',
                priority: data['priority'] ?? 'medium',
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
                confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
                confirmedBy: data['confirmedBy'],
                isRead: true,
                readAt: null,
                readBy: null,
                rejectionReason: null,
                attachmentUrls: const [],
                links: const [],
                completionComment: data['completionComment'],
                submittedAt: null,
                reviewComment: data['reviewComment'],
                initialAttachments: const [],
                initialLinks: const [],
                initialInstructions: null,
              );
            }).toList());
  }

  /// Devuelve todas las tareas completadas (para admins).
  static Stream<List<TaskModel>> getAllCompletedTasks() {
    return _firestore
        .collection('completed_tasks')
        .orderBy('completedAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return TaskModel(
                id: data['taskId'] ?? doc.id,
                title: data['title'] ?? '',
                description: data['description'] ?? '',
                dueDate: (data['dueDate'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                assignedTo: data['assignedTo'] ?? '',
                createdBy: data['createdBy'] ?? '',
                isPersonal: data['isPersonal'] ?? false,
                status: data['status'] ?? 'completed',
                priority: data['priority'] ?? 'medium',
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
                confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
                confirmedBy: data['confirmedBy'],
                isRead: true,
                readAt: null,
                readBy: null,
                rejectionReason: null,
                attachmentUrls: const [],
                links: const [],
                completionComment: data['completionComment'],
                submittedAt: null,
                reviewComment: data['reviewComment'],
                initialAttachments: const [],
                initialLinks: const [],
                initialInstructions: null,
              );
            }).toList());
  }
}
