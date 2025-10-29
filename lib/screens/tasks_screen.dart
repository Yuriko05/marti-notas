import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/task_cleanup_service.dart';
import '../theme/app_theme.dart';
import 'tasks/task_header.dart';
import 'tasks/task_tab_bar.dart';
import 'tasks/task_list.dart';
import 'tasks/task_modal.dart';

/// Pantalla principal de visualización y gestión de tareas personales
/// Incluye tabs para pendientes, en progreso y completadas
/// Refactorizada en componentes modulares para mejor mantenibilidad
class TasksScreen extends StatefulWidget {
  final UserModel user;

  const TasksScreen({super.key, required this.user});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // 3 pestañas: Pendientes, En Progreso, Completadas
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Ejecutar limpieza automática de tareas completadas al cargar la pantalla
    _performAutomaticCleanup();
  }

  /// Ejecuta la limpieza automática de tareas completadas después de 24 horas
  Future<void> _performAutomaticCleanup() async {
    try {
      await TaskCleanupService.cleanupCompletedTasks();
    } catch (e) {
      debugPrint('Error durante limpieza automática: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
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
              AppColors.backgroundLight,
              Color(0xFFE8F5E9),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              TaskHeader(
                user: widget.user,
                onBack: () => Navigator.pop(context),
              ),
              TaskTabBar(
                tabController: _tabController,
                userId: widget.user.uid,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    TaskList(
                      userId: widget.user.uid,
                      status: 'pending',
                      fadeAnimation: _fadeAnimation,
                    ),
                    TaskList(
                      userId: widget.user.uid,
                      status: 'in_progress',
                      fadeAnimation: _fadeAnimation,
                    ),
                    TaskList(
                      userId: widget.user.uid,
                      status: 'completed',
                      fadeAnimation: _fadeAnimation,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FadeTransition(
        opacity: _fadeAnimation,
        child: FloatingActionButton.extended(
          onPressed: _showCreateTaskDialog,
          backgroundColor: AppColors.secondary,
          elevation: 8,
          icon: const Icon(Icons.add_rounded,
              color: Colors.white, size: AppIconSizes.md),
          label: Text(
            'Nueva Tarea',
            style: AppTextStyles.button.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _showCreateTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => TaskModal(userId: widget.user.uid),
    );
  }
}
