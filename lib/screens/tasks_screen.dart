import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/task_status.dart';
import '../services/task_service.dart';
import '../services/task_cleanup_service.dart';
import '../theme/app_theme.dart';
import 'tasks/task_header.dart';
import 'tasks/task_tab_bar.dart';
import 'tasks/task_list.dart';
import 'tasks/task_modal.dart';
import 'tasks/user_task_stats.dart';
import 'tasks/user_task_search_bar.dart';

/// Pantalla principal de visualización y gestión de tareas personales
/// Incluye tabs para pendientes, en progreso y completadas
/// MEJORADO: Con estadísticas, búsqueda, filtros y mejor UX móvil
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
  
  // Estados para búsqueda y filtros
  String searchQuery = '';
  String priorityFilter = 'all';
  List<TaskModel> allTasks = [];

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
    
    // Cargar todas las tareas para estadísticas
    _loadAllTasks();
  }

  /// Ejecuta la limpieza automática de tareas completadas después de 24 horas
  Future<void> _performAutomaticCleanup() async {
    try {
      await TaskCleanupService.cleanupCompletedTasks();
    } catch (e) {
      debugPrint('Error durante limpieza automática: $e');
    }
  }
  
  /// Carga todas las tareas del usuario para mostrar estadísticas
  void _loadAllTasks() {
    TaskService.getUserTasks(widget.user.uid).listen((tasks) {
      if (mounted) {
        setState(() {
          allTasks = tasks;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
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
          child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }
  
  /// Layout para móviles con scroll completo
  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: TaskHeader(
            user: widget.user,
            onBack: () => Navigator.pop(context),
          ),
        ),
        
        // Estadísticas
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: UserTaskStats(allTasks: allTasks),
          ),
        ),
        
        // Búsqueda y filtros
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: UserTaskSearchBar(
              searchQuery: searchQuery,
              priorityFilter: priorityFilter,
              onSearchChanged: (value) => setState(() => searchQuery = value),
              onPriorityChanged: (value) => setState(() => priorityFilter = value!),
            ),
          ),
        ),
        
        // Tab bar
        SliverToBoxAdapter(
          child: TaskTabBar(
            tabController: _tabController,
            userId: widget.user.uid,
          ),
        ),
        
        // Lista de tareas
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              TaskList(
                userId: widget.user.uid,
                status: TaskStatus.pending,
                fadeAnimation: _fadeAnimation,
                searchQuery: searchQuery,
                priorityFilter: priorityFilter,
              ),
              TaskList(
                userId: widget.user.uid,
                status: TaskStatus.inProgress,
                fadeAnimation: _fadeAnimation,
                searchQuery: searchQuery,
                priorityFilter: priorityFilter,
              ),
              TaskList(
                userId: widget.user.uid,
                status: TaskStatus.completed,
                fadeAnimation: _fadeAnimation,
                searchQuery: searchQuery,
                priorityFilter: priorityFilter,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Layout para desktop/tablet con stats fijos
  Widget _buildDesktopLayout() {
    return Column(
      children: [
        TaskHeader(
          user: widget.user,
          onBack: () => Navigator.pop(context),
        ),
        
        FadeTransition(
          opacity: _fadeAnimation,
          child: UserTaskStats(allTasks: allTasks),
        ),
        
        FadeTransition(
          opacity: _fadeAnimation,
          child: UserTaskSearchBar(
            searchQuery: searchQuery,
            priorityFilter: priorityFilter,
            onSearchChanged: (value) => setState(() => searchQuery = value),
            onPriorityChanged: (value) => setState(() => priorityFilter = value!),
          ),
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
                status: TaskStatus.pending,
                fadeAnimation: _fadeAnimation,
                searchQuery: searchQuery,
                priorityFilter: priorityFilter,
              ),
              TaskList(
                userId: widget.user.uid,
                status: TaskStatus.inProgress,
                fadeAnimation: _fadeAnimation,
                searchQuery: searchQuery,
                priorityFilter: priorityFilter,
              ),
              TaskList(
                userId: widget.user.uid,
                status: TaskStatus.completed,
                fadeAnimation: _fadeAnimation,
                searchQuery: searchQuery,
                priorityFilter: priorityFilter,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildFAB() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: isMobile
          ? FloatingActionButton(
              onPressed: _showCreateTaskDialog,
              backgroundColor: AppColors.secondary,
              elevation: 8,
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: AppIconSizes.md,
              ),
            )
          : FloatingActionButton.extended(
              onPressed: _showCreateTaskDialog,
              backgroundColor: AppColors.secondary,
              elevation: 8,
              icon: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: AppIconSizes.md,
              ),
              label: Text(
                'Nueva Tarea',
                style: AppTextStyles.button.copyWith(color: Colors.white),
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
