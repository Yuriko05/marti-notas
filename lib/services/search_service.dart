import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../models/task_status.dart';

/// Modelo de filtros aplicados a las búsquedas de tareas.
class TaskSearchFilters {
  static const Object _sentinel = Object();

  final String query;
  final TaskStatus? status;
  final TaskPriority? priority;
  final DateTimeRange? dueDateRange;
  final bool onlyOverdue;

  const TaskSearchFilters({
    this.query = '',
    this.status,
    this.priority,
    this.dueDateRange,
    this.onlyOverdue = false,
  });

  TaskSearchFilters copyWith({
    String? query,
    Object? status = _sentinel,
    Object? priority = _sentinel,
    Object? dueDateRange = _sentinel,
    bool? onlyOverdue,
  }) {
    return TaskSearchFilters(
      query: query ?? this.query,
      status: status == _sentinel ? this.status : status as TaskStatus?,
      priority: priority == _sentinel ? this.priority : priority as TaskPriority?,
      dueDateRange:
          dueDateRange == _sentinel ? this.dueDateRange : dueDateRange as DateTimeRange?,
      onlyOverdue: onlyOverdue ?? this.onlyOverdue,
    );
  }

  bool get hasActiveFilters {
    return query.isNotEmpty ||
        status != null ||
        priority != null ||
        dueDateRange != null ||
        onlyOverdue;
  }
}

/// Servicio utilitario para aplicar filtros y búsquedas a colecciones de tareas.
class SearchService {
  /// Aplica todos los filtros indicados y devuelve la lista resultante.
  static List<TaskModel> applyFilters(
    List<TaskModel> tasks,
    TaskSearchFilters filters,
  ) {
    final byQuery = filterByQuery(tasks, filters.query);
    final byStatus = filterByStatus(byQuery, filters.status, onlyOverdue: filters.onlyOverdue);
    final byPriority = filterByPriority(byStatus, filters.priority);
    return filterByDueDateRange(byPriority, filters.dueDateRange);
  }

  /// Filtra tareas por coincidencia de texto en título, descripción o instrucciones.
  static List<TaskModel> filterByQuery(List<TaskModel> tasks, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return tasks;
    }

    return tasks.where((task) {
      final candidates = <String?>[
        task.title,
        task.description,
        task.initialInstructions,
        task.reviewComment,
        task.completionComment,
      ];

      final textMatch = candidates.any(
        (text) => text != null && text.toLowerCase().contains(normalized),
      );

      if (textMatch) {
        return true;
      }

      return task.comments.any(
        (comment) => comment.message.toLowerCase().contains(normalized),
      );
    }).toList();
  }

  /// Filtra por estado de la tarea o marca sólo vencidas si se indica.
  static List<TaskModel> filterByStatus(
    List<TaskModel> tasks,
    TaskStatus? status, {
    bool onlyOverdue = false,
  }) {
    Iterable<TaskModel> filtered = tasks;

    if (status != null) {
      filtered = filtered.where((task) => task.status == status);
    }

    if (onlyOverdue) {
      filtered = filtered.where((task) => task.isOverdue);
    }

    return filtered.toList();
  }

  /// Filtra por prioridad de la tarea.
  static List<TaskModel> filterByPriority(
      List<TaskModel> tasks, TaskPriority? priority) {
    if (priority == null) {
      return tasks;
    }

    return tasks.where((task) => task.priority == priority).toList();
  }

  /// Devuelve las tareas cuyo dueDate esté dentro del rango dado (inclusive).
  static List<TaskModel> filterByDueDateRange(
      List<TaskModel> tasks, DateTimeRange? range) {
    if (range == null) {
      return tasks;
    }

    return tasks.where((task) {
      final dueDate = task.dueDate;
      final start = DateTime(range.start.year, range.start.month, range.start.day);
      final end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
      return !dueDate.isBefore(start) && !dueDate.isAfter(end);
    }).toList();
  }
}
