import 'dart:async';

import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/admin_service.dart';
import '../services/task_cleanup_service.dart';
import '../widgets/bulk_actions_bar.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widgets.dart';
import 'simple_task_assign/simple_task_header.dart';
import 'simple_task_assign/simple_task_stats.dart';
import 'simple_task_assign/simple_task_search_bar.dart';
import 'simple_task_assign/simple_task_list.dart';
import 'simple_task_assign/task_dialogs.dart';
import 'simple_task_assign/bulk_action_handlers.dart';
import '../widgets/task_history_panel.dart';


class SimpleTaskAssignScreen extends StatefulWidget {
  final UserModel currentUser;

  const SimpleTaskAssignScreen({super.key, required this.currentUser});

  @override
  State<SimpleTaskAssignScreen> createState() => _SimpleTaskAssignScreenState();
}

class _SimpleTaskAssignScreenState extends State<SimpleTaskAssignScreen> {
  List<UserModel> users = [];
  List<TaskModel> assignedTasks = [];
  bool isLoading = true;
  StreamSubscription<List<TaskModel>>? _tasksSubscription;
  String searchQuery = '';
  String statusFilter = 'all';
  final Set<String> _selectedTaskIds = {};
  TaskModel? _selectedTask; // Para el panel de historial

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToTasksStream();
    
    // Limpieza automática para admins
    if (widget.currentUser.isAdmin) {
      _performAutomaticCleanup();
    }
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      final loadedUsers = await AdminService.getAllUsers();
      final loadedTasks = await AdminService.getAssignedTasks();

      setState(() {
        users = loadedUsers.where((user) => !user.isAdmin).toList();
        assignedTasks = loadedTasks;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  void _subscribeToTasksStream() {
    // Cancel existing
    _tasksSubscription?.cancel();
    _tasksSubscription = AdminService.streamAssignedTasks().listen((tasks) {
      if (mounted) {
        setState(() {
          assignedTasks = tasks;
          isLoading = false;
          // Sincronizar tarea seleccionada si cambió
          if (_selectedTask != null) {
            try {
              _selectedTask = tasks.firstWhere((task) => task.id == _selectedTask!.id);
            } catch (_) {
              _selectedTask = null; // Tarea ya no existe
            }
          }
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    });
  }

  /// Limpieza automática de tareas completadas (solo admins)
  Future<void> _performAutomaticCleanup() async {
    try {
      await TaskCleanupService.adminCleanupAllCompletedTasks();
    } catch (e) {
      print('Error durante limpieza automática: $e');
    }
  }

  /// Callback para seleccionar una tarea y ver su historial
  void _handleTaskSelected(TaskModel task) {
    setState(() => _selectedTask = task);
    
    // En móviles, mostrar historial como modal
    if (MediaQuery.of(context).size.width < 600 && widget.currentUser.isAdmin) {
      _showHistoryModal(task);
    }
  }

  /// Muestra el historial en un bottom sheet modal
  void _showHistoryModal(TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle para arrastrar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Título y botón cerrar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Historial de Tarea',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Historial con scroll
              Expanded(
                child: TaskHistoryPanel(task: task),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientCorporate,
        ),
        child: SafeArea(
          child: Column(
            children: [
              SimpleTaskHeader(
                onBack: () => Navigator.pop(context),
                onRefresh: _loadData,
              ),
              Expanded(
                child: isLoading
                    ? _buildLoadingState()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // Breakpoint optimizado para móviles
                          final isMobile = constraints.maxWidth < 600;
                          
                          // Layout responsivo
                          if (isMobile) {
                            // Mobile: todo scrollable (stats + lista)
                            return CustomScrollView(
                              slivers: [
                                // Stats scrollable
                                SliverToBoxAdapter(
                                  child: SimpleTaskStats(tasks: assignedTasks),
                                ),
                                // Search bar scrollable
                                SliverToBoxAdapter(
                                  child: SimpleTaskSearchBar(
                                    searchQuery: searchQuery,
                                    statusFilter: statusFilter,
                                    onSearchChanged: (value) {
                                      setState(() => searchQuery = value);
                                    },
                                    onFilterChanged: (value) {
                                      setState(() => statusFilter = value!);
                                    },
                                  ),
                                ),
                                // Lista de tareas
                                SliverFillRemaining(
                                  child: SimpleTaskList(
                                    tasks: assignedTasks,
                                    users: users,
                                    searchQuery: searchQuery,
                                    statusFilter: statusFilter,
                                    onEdit: _showEditTaskDialog,
                                    onDelete: _showDeleteTaskDialog,
                                    currentUserId: widget.currentUser.uid,
                                    selectedTaskIds: _selectedTaskIds,
                                    onTaskToggleSelection: _handleTaskToggleSelection,
                                    selectedTask: _selectedTask,
                                    onTaskSelected: _handleTaskSelected,
                                  ),
                                ),
                              ],
                            );
                          }

                          // Desktop/Tablet: Layout con stats y search fijos, lista scrollable
                          return Column(
                            children: [
                              SimpleTaskStats(tasks: assignedTasks),
                              SimpleTaskSearchBar(
                                searchQuery: searchQuery,
                                statusFilter: statusFilter,
                                onSearchChanged: (value) {
                                  setState(() => searchQuery = value);
                                },
                                onFilterChanged: (value) {
                                  setState(() => statusFilter = value!);
                                },
                              ),
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: SimpleTaskList(
                                        tasks: assignedTasks,
                                        users: users,
                                        searchQuery: searchQuery,
                                        statusFilter: statusFilter,
                                        onEdit: _showEditTaskDialog,
                                        onDelete: _showDeleteTaskDialog,
                                        currentUserId: widget.currentUser.uid,
                                        selectedTaskIds: _selectedTaskIds,
                                        onTaskToggleSelection: _handleTaskToggleSelection,
                                        selectedTask: _selectedTask,
                                        onTaskSelected: _handleTaskSelected,
                                      ),
                                    ),
                                    if (widget.currentUser.isAdmin)
                                      TaskHistoryPanel(
                                        task: _selectedTask,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // Bulk actions bar - asegurar que no tape contenido en móviles
      bottomSheet: _selectedTaskIds.isNotEmpty
          ? SafeArea(
              child: BulkActionsBar(
                selectedCount: _selectedTaskIds.length,
                onClearSelection: _clearSelection,
                onReassign: _handleBulkReassign,
                onChangePriority: _handleBulkChangePriority,
                onDelete: _handleBulkDelete,
                onMarkAsRead: _handleBulkMarkAsRead,
              ),
            )
          : null,
    );
  }

  Widget _buildLoadingState() {
    return const AppLoadingIndicator(
      message: 'Cargando datos...',
    );
  }

  Widget _buildFloatingActionButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // En móviles, FAB más compacto
        if (MediaQuery.of(context).size.width < 600) {
          return FloatingActionButton(
            onPressed: _showSimpleAssignDialog,
            backgroundColor: AppColors.secondary,
            child: const Icon(Icons.add_task_rounded, size: AppIconSizes.md),
          );
        }
        
        // En tablets/desktop, FAB extendido con texto
        return FloatingActionButton.extended(
          onPressed: _showSimpleAssignDialog,
          backgroundColor: AppColors.secondary,
          icon: const Icon(Icons.add_task_rounded, size: AppIconSizes.md),
          label: Text(
            'Nueva Tarea',
            style: AppTextStyles.button.copyWith(color: Colors.white),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }

  // ========== Métodos de UI/Diálogos ==========

  void _showEditTaskDialog(TaskModel task) {
    TaskDialogs.showEditTaskDialog(
      context: context,
      task: task,
      onSuccess: _loadData,
    );
  }

  void _showDeleteTaskDialog(TaskModel task) {
    TaskDialogs.showDeleteTaskDialog(
      context: context,
      task: task,
      onSuccess: _loadData,
    );
  }

  void _showSimpleAssignDialog() {
    TaskDialogs.showSimpleAssignDialog(
      context: context,
      users: users,
      onSuccess: _loadData,
    );
  }

  // ========== Métodos de Selección ==========

  void _handleTaskToggleSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedTaskIds.clear());
  }

  // ========== Bulk Action Handlers ==========

  Future<void> _handleBulkReassign() async {
    await BulkActionHandlers.handleBulkReassign(
      context: context,
      selectedTaskIds: _selectedTaskIds,
      users: users,
      currentUser: widget.currentUser,
      onSuccess: _loadData,
      onClearSelection: _clearSelection,
    );
  }

  Future<void> _handleBulkChangePriority() async {
    await BulkActionHandlers.handleBulkChangePriority(
      context: context,
      selectedTaskIds: _selectedTaskIds,
      currentUser: widget.currentUser,
      onSuccess: _loadData,
      onClearSelection: _clearSelection,
    );
  }

  Future<void> _handleBulkDelete() async {
    await BulkActionHandlers.handleBulkDelete(
      context: context,
      selectedTaskIds: _selectedTaskIds,
      currentUser: widget.currentUser,
      onSuccess: _loadData,
      onClearSelection: _clearSelection,
    );
  }

  Future<void> _handleBulkMarkAsRead() async {
    await BulkActionHandlers.handleBulkMarkAsRead(
      context: context,
      selectedTaskIds: _selectedTaskIds,
      onSuccess: _loadData,
      onClearSelection: _clearSelection,
    );
  }
}
