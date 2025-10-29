import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/task_service.dart';

/// Provider para el manejo de estado de tareas
/// Centraliza la lógica de tareas y notifica cambios a la UI
class TaskProvider with ChangeNotifier {
  List<TaskModel> _tasks = [];
  Map<UserModel, List<TaskModel>> _tasksGroupedByUser = {};
  Map<String, int> _confirmationStats = {};
  bool _isLoading = false;
  String? _errorMessage;

  TaskProvider();

  // Getters
  List<TaskModel> get tasks => _tasks;
  Map<UserModel, List<TaskModel>> get tasksGroupedByUser => _tasksGroupedByUser;
  Map<String, int> get confirmationStats => _confirmationStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Marcar tarea como leída
  Future<bool> markTaskAsRead(String taskId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await TaskService.markTaskAsRead(taskId);

      _isLoading = false;
      
      if (!success) {
        _errorMessage = 'Error al marcar tarea como leída';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Admin confirma tarea completada
  Future<bool> confirmTask(String taskId, {String? notes}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await TaskService.confirmTask(taskId, notes: notes);

      _isLoading = false;
      
      if (!success) {
        _errorMessage = 'Error al confirmar tarea';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Admin rechaza tarea completada
  Future<bool> rejectTask(String taskId, String reason) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await TaskService.rejectTask(taskId, reason);

      _isLoading = false;
      
      if (!success) {
        _errorMessage = 'Error al rechazar tarea';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Iniciar tarea (cambiar a en progreso)
  Future<bool> startTask(String taskId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await TaskService.startTask(taskId);

      _isLoading = false;
      
      if (!success) {
        _errorMessage = 'Error al iniciar tarea';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Completar tarea
  Future<bool> completeTask(String taskId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await TaskService.completeTask(taskId);

      _isLoading = false;
      
      if (!success) {
        _errorMessage = 'Error al completar tarea';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Revertir estado de tarea
  Future<bool> revertTaskStatus(String taskId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await TaskService.revertTaskStatus(taskId);

      _isLoading = false;
      
      if (!success) {
        _errorMessage = 'Error al revertir estado de tarea';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Cargar tareas agrupadas por usuario (para admin)
  Future<void> loadTasksGroupedByUser() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _tasksGroupedByUser = await TaskService.getTasksGroupedByUser();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al cargar tareas: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Cargar estadísticas de confirmación
  Future<void> loadConfirmationStats() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _confirmationStats = await TaskService.getConfirmationStats();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al cargar estadísticas: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Stream de tareas que necesitan confirmación
  Stream<List<TaskModel>> getTasksNeedingConfirmation() {
    return TaskService.getTasksNeedingConfirmation();
  }

  /// Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpiar todos los datos
  void clear() {
    _tasks = [];
    _tasksGroupedByUser = {};
    _confirmationStats = {};
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
