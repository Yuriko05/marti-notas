import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'unauthorized_screen.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'package:intl/intl.dart';
import '../widgets/task_preview_dialog.dart';

class AdminTasksByUserScreen extends StatefulWidget {
  final UserModel? currentUser;

  const AdminTasksByUserScreen({super.key, this.currentUser});

  @override
  State<AdminTasksByUserScreen> createState() => _AdminTasksByUserScreenState();
}

class _AdminTasksByUserScreenState extends State<AdminTasksByUserScreen> {
  Map<UserModel, List<TaskModel>> groupedTasks = {};
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final tasks = await TaskService.getTasksGroupedByUser();
    setState(() {
      groupedTasks = tasks;
      isLoading = false;
    });
  }

  List<MapEntry<UserModel, List<TaskModel>>> get filteredTasks {
    if (searchQuery.isEmpty) return groupedTasks.entries.toList();

    return groupedTasks.entries.where((entry) {
      final userName = entry.key.name.toLowerCase();
      final query = searchQuery.toLowerCase();
      return userName.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Guard: only admins may access this screen
    if (widget.currentUser == null || !widget.currentUser!.isAdmin) {
      return const UnauthorizedScreen();
    }

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
              _buildAppBar(),
              _buildSearchBar(),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : _buildUserTasksList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tareas por Usuario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${groupedTasks.length} usuarios con tareas',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        onChanged: (value) => setState(() => searchQuery = value),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar usuario...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildUserTasksList() {
    final filtered = filteredTasks;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined,
                size: 80, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 20),
            Text(
              'No hay tareas asignadas',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF1E3C72),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final entry = filtered[index];
          return _buildUserPanel(entry.key, entry.value);
        },
      ),
    );
  }

  Widget _buildUserPanel(UserModel user, List<TaskModel> tasks) {
    final pendingCount = tasks.where((t) => t.isPending).length;
    final inProgressCount = tasks.where((t) => t.isInProgress).length;
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final confirmedCount = tasks.where((t) => t.isConfirmed).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(20),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF1E3C72),
            child: Text(
              user.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            user.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3C72),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildMiniChip('Pendientes', pendingCount, Colors.orange),
                _buildMiniChip('En Progreso', inProgressCount, Colors.blue),
                _buildMiniChip('Completadas', completedCount, Colors.green),
                if (confirmedCount > 0)
                  _buildMiniChip('Confirmadas', confirmedCount, Colors.teal),
              ],
            ),
          ),
          children: tasks.map((task) => _buildTaskItem(task)).toList(),
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTaskItem(TaskModel task) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (task.isConfirmed) {
      statusColor = Colors.teal;
      statusIcon = Icons.verified;
      statusText = 'Confirmada';
    } else if (task.isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Completada';
    } else if (task.isInProgress) {
      statusColor = Colors.blue;
      statusIcon = Icons.hourglass_bottom;
      statusText = 'En Progreso';
    } else if (task.isRejected) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Rechazada';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      statusText = 'Pendiente';
    }

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => TaskPreviewDialog(task: task),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!task.isPersonal)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Icon(
                      task.isRead ? Icons.done_all : Icons.done,
                      color: task.isRead ? Colors.blue : Colors.grey[400],
                      size: 20,
                    ),
                  ),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3C72),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Vence: ${DateFormat('dd/MM/yyyy').format(task.dueDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (task.isRead && task.readAt != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Leído: ${DateFormat('dd/MM HH:mm').format(task.readAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            if (task.isCompleted) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmTask(task),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Confirmar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectTask(task),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rechazar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (task.isRejected && task.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rechazada: ${task.rejectionReason}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmTask(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Tarea'),
        content: Text(
            '¿Confirmar que "${task.title}" fue completada correctamente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await TaskService.confirmTask(task.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tarea confirmada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    }
  }

  Future<void> _rejectTask(TaskModel task) async {
    final reasonController = TextEditingController();

    final rejected = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Tarea'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Por qué rechazas "${task.title}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Motivo del rechazo...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debes escribir un motivo'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (rejected == true && reasonController.text.trim().isNotEmpty) {
      final success =
          await TaskService.rejectTask(task.id, reasonController.text.trim());
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Tarea rechazada. Usuario notificado.'),
            backgroundColor: Colors.red,
          ),
        );
        _loadData();
      }
    }
  }
}
