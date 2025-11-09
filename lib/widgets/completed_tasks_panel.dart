import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/completed_tasks_service.dart';
import '../models/user_model.dart';
import '../services/auth/user_repository.dart';

class CompletedTasksPanel extends StatefulWidget {
  final String? userId;
  const CompletedTasksPanel({super.key, this.userId});

  @override
  State<CompletedTasksPanel> createState() => _CompletedTasksPanelState();
}

class _CompletedTasksPanelState extends State<CompletedTasksPanel> {
  String _searchQuery = '';
  String _priorityFilter = 'all';
  String _sortBy = 'date'; // date, priority, duration
  Map<String, UserModel> _usersCache = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await UserRepository().getAllUsers();
      setState(() {
        _usersCache = {for (var user in users) user.uid: user};
      });
    } catch (e) {
      debugPrint('Error cargando usuarios: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si userId es nulo, mostramos todas las tareas completadas (vista admin)
    final isGlobalView = widget.userId == null;

    return Container(
      // permitir expandir en un diálogo a pantalla completa
      constraints: const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.history,
                  color: Color(0xFF2196F3),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isGlobalView ? 'Tareas Completadas (Todas)' : 'Tareas Completadas',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (isGlobalView)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Chip(
                      label: const Text('Admin', style: TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: Colors.grey.shade700,
                    ),
                  ),
              ],
            ),
          ),
          // Barra de búsqueda y filtros
          if (isGlobalView)
            _buildSearchAndFilters(),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<TaskModel>>(
              stream: isGlobalView
                  ? CompletedTasksService.getAllCompletedTasks()
                  : CompletedTasksService.getUserCompletedTasks(widget.userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error al cargar: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
                
                var tasks = snapshot.data ?? [];
                
                // Calcular estadísticas antes de filtrar
                final stats = isGlobalView ? _calculateStats(tasks) : null;
                
                // Aplicar filtros y búsqueda
                tasks = _applyFilters(tasks);
                
                if (tasks.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No hay tareas completadas',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return Column(
                  children: [
                    // Estadísticas
                    if (isGlobalView && stats != null)
                      _buildStatsBar(stats),
                    // Lista de tareas
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: tasks.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _buildTaskTile(task);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por título o descripción...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 8),
          // Filtros
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _priorityFilter,
                  decoration: InputDecoration(
                    labelText: 'Prioridad',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Todas')),
                    DropdownMenuItem(value: 'high', child: Text('Alta')),
                    DropdownMenuItem(value: 'medium', child: Text('Media')),
                    DropdownMenuItem(value: 'low', child: Text('Baja')),
                  ],
                  onChanged: (value) => setState(() => _priorityFilter = value!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Ordenar por',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'date', child: Text('Fecha')),
                    DropdownMenuItem(value: 'priority', child: Text('Prioridad')),
                    DropdownMenuItem(value: 'duration', child: Text('Duración')),
                  ],
                  onChanged: (value) => setState(() => _sortBy = value!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<TaskModel> _applyFilters(List<TaskModel> tasks) {
    var filtered = tasks;

    // Aplicar filtro de búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        final query = _searchQuery.toLowerCase();
        return task.title.toLowerCase().contains(query) ||
               task.description.toLowerCase().contains(query);
      }).toList();
    }

    // Aplicar filtro de prioridad
    if (_priorityFilter != 'all') {
      filtered = filtered.where((task) => task.priority == _priorityFilter).toList();
    }

    // Aplicar ordenamiento
    switch (_sortBy) {
      case 'date':
        filtered.sort((a, b) {
          final dateA = a.completedAt ?? a.confirmedAt ?? DateTime(2000);
          final dateB = b.completedAt ?? b.confirmedAt ?? DateTime(2000);
          return dateB.compareTo(dateA); // Más reciente primero
        });
        break;
      case 'priority':
        filtered.sort((a, b) {
          const priorityOrder = {'high': 3, 'medium': 2, 'low': 1};
          return (priorityOrder[b.priority] ?? 0).compareTo(priorityOrder[a.priority] ?? 0);
        });
        break;
      case 'duration':
        filtered.sort((a, b) {
          final durationA = _calculateDuration(a);
          final durationB = _calculateDuration(b);
          return durationB.compareTo(durationA);
        });
        break;
    }

    return filtered;
  }

  int _calculateDuration(TaskModel task) {
    final completed = task.completedAt ?? task.confirmedAt;
    if (completed == null) return 0;
    return completed.difference(task.createdAt).inHours;
  }

  String _formatDuration(TaskModel task) {
    final completed = task.completedAt ?? task.confirmedAt;
    if (completed == null) return 'N/A';
    
    final duration = completed.difference(task.createdAt);
    
    if (duration.inDays > 0) {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      if (hours > 0) {
        return '${days}d ${hours}h';
      }
      return '${days}d';
    } else if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  Widget _buildTaskTile(TaskModel task) {
    final completedAt = task.completedAt ?? task.confirmedAt;
    final formattedDate = completedAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(completedAt)
        : 'Sin fecha';
    
    final durationText = _formatDuration(task);

    // Obtener información del usuario
    final assignedUser = _usersCache[task.assignedTo];
    final creatorUser = _usersCache[task.createdBy];

    Color priorityColor = Colors.grey;
    IconData priorityIcon = Icons.low_priority;
    
    switch (task.priority) {
      case 'high':
        priorityColor = Colors.red;
        priorityIcon = Icons.priority_high;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        priorityIcon = Icons.remove;
        break;
      case 'low':
        priorityColor = Colors.blue;
        priorityIcon = Icons.low_priority;
        break;
    }

    return ExpansionTile(
      leading: Icon(
        Icons.check_circle,
        color: task.confirmedBy != null ? Colors.green : const Color(0xFF2196F3),
        size: 24,
      ),
      title: Text(
        task.title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(priorityIcon, size: 12, color: priorityColor),
              const SizedBox(width: 4),
              Text(
                _getPriorityLabel(task.priority),
                style: TextStyle(
                  fontSize: 11,
                  color: priorityColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.access_time, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                formattedDate,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 2),
          if (assignedUser != null)
            Row(
              children: [
                const Icon(Icons.person, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Asignado a: ${assignedUser.name}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (durationText != 'N/A')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                durationText,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (task.confirmedBy != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.verified,
              size: 18,
              color: Colors.green[600],
            ),
          ],
        ],
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Descripción
              if (task.description.isNotEmpty) ...[
                const Text(
                  'Descripción:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 12),
              ],
              // Información adicional
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fecha de vencimiento:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(task.dueDate),
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tiempo de completado:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          durationText != 'N/A' ? durationText : 'Sin calcular',
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Fechas detalladas
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fecha de creación:',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(task.createdAt),
                              style: const TextStyle(fontSize: 10, color: Colors.black87),
                            ),
                          ],
                        ),
                        if (completedAt != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Fecha de completado:',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(completedAt),
                                style: const TextStyle(fontSize: 10, color: Colors.black87),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Creador
              if (creatorUser != null) ...[
                Row(
                  children: [
                    const Text(
                      'Creada por: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      creatorUser.name,
                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              // Comentarios
              if (task.completionComment != null && task.completionComment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Comentario de completado:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    task.completionComment!,
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ),
              ],
              if (task.reviewComment != null && task.reviewComment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Comentario de revisión:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    task.reviewComment!,
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _calculateStats(List<TaskModel> tasks) {
    int totalTasks = tasks.length;
    int highPriority = tasks.where((t) => t.priority == 'high').length;
    int mediumPriority = tasks.where((t) => t.priority == 'medium').length;
    int lowPriority = tasks.where((t) => t.priority == 'low').length;
    int verified = tasks.where((t) => t.confirmedBy != null).length;
    
    // Calcular duración promedio
    final durations = tasks.map((t) => _calculateDuration(t)).where((d) => d > 0).toList();
    final avgDuration = durations.isNotEmpty 
        ? (durations.reduce((a, b) => a + b) / durations.length).round()
        : 0;

    return {
      'total': totalTasks,
      'high': highPriority,
      'medium': mediumPriority,
      'low': lowPriority,
      'verified': verified,
      'avgDuration': avgDuration,
    };
  }

  Widget _buildStatsBar(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.task_alt,
            label: 'Total',
            value: stats['total'].toString(),
            color: Colors.blue,
          ),
          _buildStatItem(
            icon: Icons.verified,
            label: 'Verificadas',
            value: stats['verified'].toString(),
            color: Colors.green,
          ),
          _buildStatItem(
            icon: Icons.access_time,
            label: 'Promedio',
            value: '${stats['avgDuration']}h',
            color: Colors.orange,
          ),
          _buildStatItem(
            icon: Icons.priority_high,
            label: 'Alta',
            value: stats['high'].toString(),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return 'Alta';
      case 'medium':
        return 'Media';
      case 'low':
        return 'Baja';
      default:
        return priority;
    }
  }
}
