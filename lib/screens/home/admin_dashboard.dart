import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/user_model.dart';
import '../../models/task_model.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/task_review_dialog.dart';

class AdminDashboard extends StatefulWidget {
  final UserModel admin;

  const AdminDashboard({
    Key? key,
    required this.admin,
  }) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<UserModel> _allUsers = [];
  List<TaskModel> _allTasks = [];
  bool _isLoading = true;
  StreamSubscription<List<TaskModel>>? _tasksSubscription;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _subscribeToTasksStream();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final users = await AdminService.getAllUsers();
      
      // Obtener todas las tareas asignadas por el admin
      final allTasks = await AdminService.getAssignedTasks();

      print('📊 AdminDashboard: Cargados ${users.length} usuarios y ${allTasks.length} tareas');

      if (mounted) {
        setState(() {
          _allUsers = users.where((u) => !u.isAdmin).toList();
          _allTasks = allTasks;
          _isLoading = false;
        });
        
        print('📊 AdminDashboard: Mostrando ${_allUsers.length} usuarios (no admin) y ${_allTasks.length} tareas');
      }
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToTasksStream() {
    _tasksSubscription?.cancel();
    _tasksSubscription = AdminService.streamAssignedTasks().listen((tasks) {
      if (mounted) {
        print('📊 AdminDashboard: Tareas actualizadas: ${tasks.length} tareas');
        setState(() {
          _allTasks = tasks;
        });
      }
    }, onError: (e) {
      print('❌ Error en stream de tareas: $e');
    });
  }

  Map<String, int> _calculateGlobalStats() {
    final now = DateTime.now();
    int pending = 0;
    int inProgress = 0;
    int completed = 0;
    int pendingReview = 0;
    int overdue = 0;

    print('📊 Calculando stats para ${_allTasks.length} tareas');
    
    for (var task in _allTasks) {
      print('   Tarea: "${task.title}" - Status: "${task.status}"');
      
      if (task.status == 'completed') {
        completed++;
      } else if (task.status == 'in_progress') {
        inProgress++;
      } else if (task.status == 'pending_review' && !task.isPersonal) {
        // Solo contar tareas NO personales en revisión
        pendingReview++;
      } else if (task.status == 'pending') {
        pending++;
      }

      // Check if overdue
      if (task.status != 'completed' && task.dueDate.isBefore(now)) {
        overdue++;
      }
    }

    final stats = {
      'pending': pending,
      'inProgress': inProgress,
      'pendingReview': pendingReview,
      'completed': completed,
      'overdue': overdue,
      'total': _allTasks.length,
    };
    
    print('📊 Stats calculadas: Total=${stats['total']}, Pendientes=${stats['pending']}, En Progreso=${stats['inProgress']}, En Revisión=${stats['pendingReview']}, Completadas=${stats['completed']}, Vencidas=${stats['overdue']}');
    
    return stats;
  }

  Map<String, dynamic> _getUserStats(String userId) {
    final userTasks = _allTasks.where((t) => t.assignedTo == userId).toList();
    final now = DateTime.now();

    int completed = userTasks.where((t) => t.status == 'completed').length;
    int pending = userTasks.where((t) => t.status == 'pending').length;
    int inProgress = userTasks.where((t) => t.status == 'in_progress').length;
    int pendingReview = userTasks.where((t) => t.status == 'pending_review' && !t.isPersonal).length;
    int overdue = userTasks
        .where((t) => t.status != 'completed' && t.dueDate.isBefore(now))
        .length;

    double completionRate =
        userTasks.isEmpty ? 0 : (completed / userTasks.length) * 100;

    return {
      'total': userTasks.length,
      'completed': completed,
      'pending': pending,
      'inProgress': inProgress,
      'pendingReview': pendingReview,
      'overdue': overdue,
      'completionRate': completionRate,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final globalStats = _calculateGlobalStats();
    final totalUsers = _allUsers.length;
    final completionRate = globalStats['total']! > 0
        ? (globalStats['completed']! / globalStats['total']!) * 100
        : 0.0;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: CustomScrollView(
        slivers: [
          // Premium Admin Header
          SliverToBoxAdapter(
            child: _buildPremiumAdminHeader(),
          ),

          // Global Statistics Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildGlobalStatsCard(globalStats, totalUsers, completionRate),
            ),
          ),

          // Quick Overview Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildQuickOverview(globalStats),
            ),
          ),

          // Tareas en Revisión (moved arriba para visibilidad)
          if (_allTasks.where((t) => t.status == 'pending_review' && !t.isPersonal).isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    Icon(Icons.rate_review, color: const Color(0xFF667eea), size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Tareas en Revisión',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_allTasks.where((t) => t.status == 'pending_review' && !t.isPersonal).length} pendiente${_allTasks.where((t) => t.status == 'pending_review' && !t.isPersonal).length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Color(0xFF667eea),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final reviewTasks = _allTasks.where((t) => t.status == 'pending_review' && !t.isPersonal).toList();
                    if (index >= reviewTasks.length) return null;
                    final task = reviewTasks[index];
                    return _buildReviewTaskItem(task);
                  },
                  childCount: _allTasks.where((t) => t.status == 'pending_review' && !t.isPersonal).length,
                ),
              ),
            ),
          ],

          // Rendimiento por Usuario (expandible)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 12, bottom: 8),
                initiallyExpanded: false,
                title: Row(
                  children: [
                    Icon(Icons.people, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Rendimiento por Usuario',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _allUsers.length,
                      itemBuilder: (context, index) {
                        final user = _allUsers[index];
                        final stats = _getUserStats(user.uid);
                        return _buildUserPerformanceCard(user, stats);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          

          // Actividad Reciente (expandible)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 12, bottom: 8),
                initiallyExpanded: false,
                title: Row(
                  children: [
                    Icon(Icons.history, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Actividad Reciente',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Column(
                      children: [
                        for (int i = 0; i < (_allTasks.length > 10 ? 10 : _allTasks.length); i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildRecentTaskItem(_allTasks[i]),
                          ),
                        if (_allTasks.length == 0)
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              'No hay actividad reciente',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumAdminHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.3),
            child: Text(
              widget.admin.name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel de Administración',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hola, ${widget.admin.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalStatsCard(
      Map<String, int> stats, int totalUsers, double completionRate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dashboard,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen Global',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalUsers usuarios activos',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tasa de Completitud',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${completionRate.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: completionRate / 100,
                  minHeight: 10,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completionRate >= 80
                        ? AppColors.success
                        : completionRate >= 50
                            ? Colors.orange
                            : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  stats['total'].toString(),
                  Icons.assignment,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Completadas',
                  stats['completed'].toString(),
                  Icons.check_circle,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOverview(Map<String, int> stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickStatCard(
                'Pendientes',
                stats['pending'].toString(),
                Icons.pending_actions,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickStatCard(
                'En Progreso',
                stats['inProgress'].toString(),
                Icons.timer,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickStatCard(
                'Vencidas',
                stats['overdue'].toString(),
                Icons.warning,
                AppColors.error,
              ),
            ),
          ],
        ),
        // Removed the prominent pending-review banner to reduce header space.
      ],
    );
  }

  Widget _buildQuickStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserPerformanceCard(UserModel user, Map<String, dynamic> stats) {
    final completionRate = stats['completionRate'] as double;
    final hasOverdue = stats['overdue'] > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasOverdue
              ? AppColors.error.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  user.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, color: AppColors.error, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${stats['overdue']}',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Completitud',
                style: TextStyle(fontSize: 12),
              ),
              Text(
                '${completionRate.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completionRate / 100,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                completionRate >= 80
                    ? AppColors.success
                    : completionRate >= 50
                        ? Colors.orange
                        : AppColors.error,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Task Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat(
                stats['completed'].toString(),
                'Completadas',
                AppColors.success,
              ),
              _buildMiniStat(
                stats['inProgress'].toString(),
                'En Progreso',
                Colors.blue,
              ),
              _buildMiniStat(
                stats['pending'].toString(),
                'Pendientes',
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTaskItem(TaskModel task) {
    final user = _allUsers.firstWhere(
      (u) => u.uid == task.assignedTo,
      orElse: () => UserModel(
        uid: '',
        name: 'Usuario desconocido',
        email: '',
        username: '',
        role: 'user',
        createdAt: DateTime.now(),
      ),
    );

    final now = DateTime.now();
    final isOverdue = task.status != 'completed' && task.dueDate.isBefore(now);
    final daysUntilDue = task.dueDate.difference(now).inDays;

    Color statusColor;
    IconData statusIcon;
    switch (task.status) {
      case 'completed':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'in-progress':
        statusColor = Colors.blue;
        statusIcon = Icons.timer;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'VENCIDA',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                )
              else if (task.status != 'completed')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: daysUntilDue <= 2
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    daysUntilDue == 0
                        ? 'Hoy'
                        : daysUntilDue == 1
                            ? 'Mañana'
                            : '$daysUntilDue días',
                    style: TextStyle(
                      color: daysUntilDue <= 2 ? Colors.orange : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewTaskItem(TaskModel task) {
    final user = _allUsers.firstWhere(
      (u) => u.uid == task.assignedTo,
      orElse: () => UserModel(
        uid: '',
        name: 'Usuario desconocido',
        email: '',
        username: '',
        role: 'user',
        createdAt: DateTime.now(),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667eea).withOpacity(0.05),
            const Color(0xFF764ba2).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF667eea).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await showDialog(
              context: context,
              builder: (context) => TaskReviewDialog(task: task),
            );
            // El diálogo actualizará automáticamente gracias al stream
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.rate_review,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pending_actions,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'EN REVISIÓN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (task.completionComment != null &&
                    task.completionComment!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.comment,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.completionComment!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (task.links.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.link,
                        size: 14,
                        color: const Color(0xFF667eea),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task.links.length} enlace${task.links.length > 1 ? 's' : ''} adjunto${task.links.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF667eea),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await showDialog(
                            context: context,
                            builder: (context) => TaskReviewDialog(task: task),
                          );
                        },
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Revisar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
