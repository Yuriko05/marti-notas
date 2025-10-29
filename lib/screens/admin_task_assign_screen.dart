import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../services/admin_service.dart';
import '../services/task_cleanup_service.dart';
import 'admin_task_assign/admin_task_header.dart';
import 'admin_task_assign/admin_task_stats.dart';
import 'admin_task_assign/admin_task_search_bar.dart';
import 'admin_task_assign/admin_task_list.dart';
import 'admin_task_assign/admin_task_fab.dart';
import 'admin_task_assign/admin_assign_task_dialog.dart';

/// Pantalla principal de asignación de tareas (administrador)
/// Refactorizada en componentes modulares para mejor mantenibilidad
class AdminTaskAssignScreen extends StatefulWidget {
  final UserModel currentUser;

  const AdminTaskAssignScreen({super.key, required this.currentUser});

  @override
  State<AdminTaskAssignScreen> createState() => _AdminTaskAssignScreenState();
}

class _AdminTaskAssignScreenState extends State<AdminTaskAssignScreen>
    with TickerProviderStateMixin {
  List<UserModel> _users = [];
  List<TaskModel> _assignedTasks = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();

    // Ejecutar limpieza automática de tareas completadas (solo para admins)
    _performAutomaticCleanup();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Ejecuta la limpieza automática general de todas las tareas completadas
  Future<void> _performAutomaticCleanup() async {
    try {
      await TaskCleanupService.adminCleanupAllCompletedTasks();
    } catch (e) {
      print('Error durante limpieza automática del administrador: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final loadedUsers = await AdminService.getAllUsers();
    final loadedTasks = await AdminService.getAssignedTasks();

    setState(() {
      _users = loadedUsers.where((user) => !user.isAdmin).toList();
      _assignedTasks = loadedTasks;
      _isLoading = false;
    });

    _animationController.forward();
  }

  void _showAssignTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AdminAssignTaskDialog(
        users: _users,
        onTaskAssigned: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3C72),
              Color(0xFF2A5298),
              Color(0xFF3F7CAC),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AdminTaskHeader(onRefresh: _loadData),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            AdminTaskStats(tasks: _assignedTasks),
                            AdminTaskSearchBar(
                              searchQuery: _searchQuery,
                              statusFilter: _statusFilter,
                              onSearchChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              onFilterChanged: (value) =>
                                  setState(() => _statusFilter = value),
                            ),
                            Expanded(
                              child: AdminTaskList(
                                tasks: _assignedTasks,
                                users: _users,
                                searchQuery: _searchQuery,
                                statusFilter: _statusFilter,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: AdminTaskFab(
        onAddTask: _showAssignTaskDialog,
        onCleanupComplete: _loadData,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Cargando tareas...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
