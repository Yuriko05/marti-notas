import '../models/comment.dart';
import '../models/task_model.dart';
import '../models/task_status.dart';
import '../models/user_model.dart';
import 'task/task_assignment_service.dart';
import 'task/task_lifecycle_service.dart';
import 'task/task_review_service.dart';
import 'task/task_stats_service.dart';

class TaskService {
  /// Marca la tarea como leída delegando en TaskLifecycleService.
  static Future<bool> markTaskAsRead(String taskId) {
    return TaskLifecycleService.markTaskAsRead(taskId);
  }

  /// Confirma una tarea delegando en TaskLifecycleService.
  static Future<bool> confirmTask(String taskId, {String? notes}) {
    return TaskLifecycleService.confirmTask(taskId, notes: notes);
  }

  /// Rechaza una tarea delegando en TaskLifecycleService.
  static Future<bool> rejectTask(String taskId, String reason) {
    return TaskLifecycleService.rejectTask(taskId, reason);
  }

  /// Aprueba revisiones mediante TaskReviewService.
  static Future<bool> approveTaskReview({
    required String taskId,
    String? reviewComment,
  }) {
    return TaskReviewService.approveTaskReview(
      taskId: taskId,
      reviewComment: reviewComment,
    );
  }

  /// Rechaza revisiones mediante TaskReviewService.
  static Future<bool> rejectTaskReview({
    required String taskId,
    required String reason,
  }) {
    return TaskReviewService.rejectTaskReview(
      taskId: taskId,
      reason: reason,
    );
  }

  /// Obtiene tareas agrupadas por usuario a través de TaskStatsService.
  static Future<Map<UserModel, List<TaskModel>>> getTasksGroupedByUser() {
    return TaskStatsService.getTasksGroupedByUser();
  }

  /// Recupera estadísticas de confirmación a través de TaskStatsService.
  static Future<Map<String, int>> getConfirmationStats() {
    return TaskStatsService.getConfirmationStats();
  }

  /// Stream de tareas pendientes de confirmación vía TaskStatsService.
  static Stream<List<TaskModel>> getTasksNeedingConfirmation() {
    return TaskStatsService.getTasksNeedingConfirmation();
  }

  /// Inicia una tarea mediante TaskLifecycleService.
  static Future<bool> startTask(String taskId) {
    return TaskLifecycleService.startTask(taskId);
  }

  /// Completa una tarea mediante TaskLifecycleService.
  static Future<bool> completeTask(String taskId) {
    return TaskLifecycleService.completeTask(taskId);
  }

  /// Envía una tarea a revisión delegando en TaskReviewService.
  static Future<bool> submitTaskForReview({
    required String taskId,
    String? comment,
    List<String>? links,
    List<String>? attachments,
  }) {
    return TaskReviewService.submitTaskForReview(
      taskId: taskId,
      comment: comment,
      links: links,
      attachments: attachments,
    );
  }

  /// Revierte el estado de una tarea mediante TaskLifecycleService.
  static Future<bool> revertTaskStatus(String taskId) {
    return TaskLifecycleService.revertTaskStatus(taskId);
  }

  /// Crea una tarea personal a través de TaskAssignmentService.
  static Future<String?> createPersonalTask({
    required String title,
    required String description,
    required DateTime dueDate,
  }) {
    return TaskAssignmentService.createPersonalTask(
      title: title,
      description: description,
      dueDate: dueDate,
    );
  }

  /// Stream de tareas por estado vía TaskAssignmentService.
  static Stream<List<TaskModel>> getUserTasksByStatus(
      String userId, TaskStatus status) {
    return TaskAssignmentService.getUserTasksByStatus(userId, status);
  }

  /// Stream de todas las tareas del usuario vía TaskAssignmentService.
  static Stream<List<TaskModel>> getUserTasks(String userId) {
    return TaskAssignmentService.getUserTasks(userId);
  }

  /// Actualiza una tarea personal a través de TaskAssignmentService.
  static Future<bool> updatePersonalTask({
    required String taskId,
    required String title,
    required String description,
    required DateTime dueDate,
  }) {
    return TaskAssignmentService.updatePersonalTask(
      taskId: taskId,
      title: title,
      description: description,
      dueDate: dueDate,
    );
  }

  /// Elimina una tarea personal vía TaskAssignmentService.
  static Future<bool> deletePersonalTask(String taskId) {
    return TaskAssignmentService.deletePersonalTask(taskId);
  }

  /// TODO: Persistir comentarios en Firestore (subcolección) y notificar a los involucrados.
  static Future<void> addCommentToTask({
    required String taskId,
    required Comment comment,
  }) async {
    throw UnimplementedError('TODO: Implementar addCommentToTask con Firestore');
  }

  /// TODO: Consumir los comentarios almacenados cuando se implemente el chat interno.
  static Stream<List<Comment>> streamTaskComments(String taskId) {
    throw UnimplementedError('TODO: Implementar streamTaskComments con Firestore');
  }
}
