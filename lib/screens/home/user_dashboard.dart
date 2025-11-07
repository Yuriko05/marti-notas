import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import '../tasks/user_task_stats.dart';

/// Dashboard principal del usuario con estadísticas y vista rápida
class UserDashboard extends StatefulWidget {
  final UserModel user;

  const UserDashboard({
    super.key,
    required this.user,
  });

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  List<TaskModel> allTasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    print('📊 UserDashboard: Iniciando carga de tareas para usuario ${widget.user.uid}');
    TaskService.getUserTasks(widget.user.uid).listen((tasks) {
      if (mounted) {
        print('📊 UserDashboard: Recibidas ${tasks.length} tareas');
        setState(() {
          allTasks = tasks;
          isLoading = false;
        });
      }
    }, onError: (error) {
      print('❌ UserDashboard: Error cargando tareas: $error');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final upcomingTasks = allTasks
        .where((t) => !t.isCompleted && !t.isOverdue)
        .take(5)
        .toList();
    final overdueTasks = allTasks.where((t) => t.isOverdue && !t.isCompleted).toList();
    final adminTasks = allTasks.where((t) => !t.isPersonal && !t.isCompleted).toList();

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: _buildPremiumUserHeader(),
        ),

        // Estadísticas
        SliverToBoxAdapter(
          child: UserTaskStats(allTasks: allTasks),
        ),

        // Tareas Vencidas (si hay)
        if (overdueTasks.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildOverdueTasksSection(overdueTasks),
          ),

        // Tareas del Admin (si hay)
        if (adminTasks.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildAdminTasksSection(adminTasks),
          ),

        // Próximas Tareas
        SliverToBoxAdapter(
          child: _buildUpcomingTasksSection(upcomingTasks),
        ),

        // Espaciado final
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildPremiumUserHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
            Color(0xFF667eea),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(45),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 45,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '¡Hola, ${widget.user.name}!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu panel de control personal',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueTasksSection(List<TaskModel> tasks) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFfc4a1a), width: 2),
        boxShadow: [AppColors.shadowMd],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFfc4a1a).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFfc4a1a),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ Tareas Vencidas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFfc4a1a),
                      ),
                    ),
                    Text(
                      '${tasks.length} tarea(s) requieren atención',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tasks.take(3).map((task) => _buildTaskItem(task, isOverdue: true)),
        ],
      ),
    );
  }

  Widget _buildAdminTasksSection(List<TaskModel> tasks) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppColors.shadowMd],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientCorporate,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.business_center_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎯 Tareas Asignadas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${tasks.length} tarea(s) del administrador',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tasks.take(5).map((task) => _buildTaskItem(task)),
        ],
      ),
    );
  }

  Widget _buildUpcomingTasksSection(List<TaskModel> tasks) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppColors.shadowMd],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: Color(0xFF667eea),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '📅 Próximas Tareas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      '¡Todo al día!',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ...tasks.map((task) => _buildTaskItem(task)),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TaskModel task, {bool isOverdue = false}) {
    final daysUntilDue = task.dueDate.difference(DateTime.now()).inDays;
    final dueText = daysUntilDue == 0
        ? 'Vence hoy'
        : daysUntilDue == 1
            ? 'Vence mañana'
            : daysUntilDue < 0
                ? 'Vencida hace ${-daysUntilDue} día(s)'
                : 'En $daysUntilDue día(s)';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOverdue
            ? const Color(0xFFfc4a1a).withOpacity(0.05)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverdue ? const Color(0xFFfc4a1a) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            task.isInProgress
                ? Icons.play_circle_outline
                : Icons.radio_button_unchecked,
            color: isOverdue
                ? const Color(0xFFfc4a1a)
                : task.isInProgress
                    ? const Color(0xFF667eea)
                    : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isOverdue ? const Color(0xFFfc4a1a) : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      dueText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue
                            ? const Color(0xFFfc4a1a)
                            : Colors.grey[600],
                      ),
                    ),
                    if (!task.isPersonal) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667eea).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF667eea),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
