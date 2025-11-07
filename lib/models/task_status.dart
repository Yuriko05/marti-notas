enum TaskStatus {
  pending,
  inProgress,
  pendingReview,
  completed,
  confirmed,
  rejected,
}

extension TaskStatusX on TaskStatus {
  String get value {
    switch (this) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.pendingReview:
        return 'pending_review';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.confirmed:
        return 'confirmed';
      case TaskStatus.rejected:
        return 'rejected';
    }
  }
}

TaskStatus taskStatusFromString(String? value) {
  switch (value) {
    case 'in_progress':
      return TaskStatus.inProgress;
    case 'pending_review':
      return TaskStatus.pendingReview;
    case 'completed':
      return TaskStatus.completed;
    case 'confirmed':
      return TaskStatus.confirmed;
    case 'rejected':
      return TaskStatus.rejected;
    case 'pending':
    default:
      return TaskStatus.pending;
  }
}

enum TaskPriority {
  low,
  medium,
  high,
}

extension TaskPriorityX on TaskPriority {
  String get value {
    switch (this) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.high:
        return 'high';
    }
  }
}

TaskPriority taskPriorityFromString(String? value) {
  switch (value) {
    case 'low':
      return TaskPriority.low;
    case 'high':
      return TaskPriority.high;
    case 'medium':
    default:
      return TaskPriority.medium;
  }
}
