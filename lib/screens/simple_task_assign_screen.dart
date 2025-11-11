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
import '../widgets/completed_tasks_panel.dart';
import '../widgets/task_preview_dialog.dart';
import '../widgets/task_card.dart';


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

  void _openCompletedTasksWindow() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Historial de tareas completadas')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: CompletedTasksPanel(userId: null),
            ),
          ),
        ),
      ),
    );
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
    // El admin NO debe abrir ningún diálogo ni panel lateral al hacer clic en tareas
    // Solo los usuarios asignados pueden ver el preview de sus tareas
    if (widget.currentUser.uid != task.assignedTo) {
      // Si el usuario actual NO es el asignado (es el admin), no hacer nada
      return;
    }
    
    setState(() => _selectedTask = task);
    
    // En móviles, mostrar historial como modal
    // Sólo permitir abrir el diálogo en móvil si el usuario actual es el asignado
    if (MediaQuery.of(context).size.width < 600) {
      showDialog(
        context: context,
        builder: (context) => TaskPreviewDialog(task: task, showActions: true),
      );
    }
  }

  // NOTE: mobile detail view now opens TaskPreviewDialog directly.

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
                onOpenHistory: _openCompletedTasksWindow,
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
                                // Lista de tareas como SliverList para compartir el mismo scroll
                                Builder(builder: (context) {
                                  final filtered = assignedTasks.where((task) {
                                    final matchesSearch = searchQuery.isEmpty ||
                                        task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                                        task.description.toLowerCase().contains(searchQuery.toLowerCase());
                                    final matchesStatus = statusFilter == 'all' ||
                                        (statusFilter == 'pending' && task.isPending) ||
                                        (statusFilter == 'completed' && task.isCompleted) ||
                                        (statusFilter == 'overdue' && task.isOverdue);
                                    return matchesSearch && matchesStatus;
                                  }).toList();

                                  return SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        if (index >= filtered.length) return null;
                                        final task = filtered[index];
                                        final user = users.firstWhere(
                                          (u) => u.uid == task.assignedTo,
                                          orElse: () => UserModel(
                                            uid: task.assignedTo,
                                            email: 'usuario.eliminado@example.com',
                                            name: 'Usuario eliminado',
                                            role: 'normal',
                                            username: 'usuarioeliminado',
                                            hasPassword: false,
                                            createdAt: DateTime.now(),
                                          ),
                                        );

                                        final isChecked = _selectedTaskIds.contains(task.id);
                                        final isSelected = _selectedTask?.id == task.id;

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                          child: TaskCard(
                                            task: task,
                                            user: user,
                                            isChecked: isChecked,
                                            isSelected: isSelected,
                                            onToggleSelect: (id) => _handleTaskToggleSelection(id),
                                            showActions: true,
                                            onTap: () {
                                              // seleccionar y delegar comportamiento (abrir sólo si corresponde)
                                              _handleTaskSelected(task);
                                            },
                                            onEdit: (t) => _showEditTaskDialog(t),
                                            onDelete: (t) => _showDeleteTaskDialog(t),
                                            onPreview: (t) {
                                              _handleTaskSelected(task);
                                            },
                                          ),
                                        );
                                      },
                                      childCount: filtered.length,
                                    ),
                                  );
                                }),
                              ],
                            );
                          }

                          // Desktop/Tablet: hacer que stats + search scrolleen junto con la lista
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Columna izquierda: header (stats + search) y lista que comparten scroll
                              Expanded(
                                flex: 3,
                                child: NestedScrollView(
                                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: SimpleTaskStats(tasks: assignedTasks),
                                      ),
                                    ),
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
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
                                    ),
                                  ],
                                  body: SimpleTaskList(
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
                              ),
                              // Columna derecha: espacio para panel seleccionado (si aplica)
                              if (widget.currentUser.isAdmin && _selectedTask != null)
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      children: [
                                        // Reusar TaskPreviewDialog como panel o cualquier panel detallado que prefieras
                                        Expanded(
                                          child: TaskPreviewDialog(task: _selectedTask!),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
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
