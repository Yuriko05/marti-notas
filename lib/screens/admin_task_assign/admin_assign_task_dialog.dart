import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../services/notification_service.dart';
import '../../utils/validators.dart';
import '../../utils/ui_helper.dart';

/// Diálogo para asignar nuevas tareas a usuarios
class AdminAssignTaskDialog extends StatefulWidget {
  final List<UserModel> users;
  final VoidCallback onTaskAssigned;

  const AdminAssignTaskDialog({
    super.key,
    required this.users,
    required this.onTaskAssigned,
  });

  @override
  State<AdminAssignTaskDialog> createState() => _AdminAssignTaskDialogState();
}

class _AdminAssignTaskDialogState extends State<AdminAssignTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String? _selectedUserId;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.users.isEmpty) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('No hay usuarios disponibles'),
        content: const Text(
          'No hay usuarios registrados para asignar tareas. Primero debes crear usuarios en el sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assignment_add,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text('Asignar Nueva Tarea'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título de la tarea',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                  hintText: 'Ingresa el título',
                ),
                validator: FormValidators.validateTitle,
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Describe la tarea',
                ),
                validator: FormValidators.validateDescription,
                maxLength: 500,
              ),
              const SizedBox(height: 16),

              // Usuario
              DropdownButtonFormField<String>(
                value: _selectedUserId,
                decoration: const InputDecoration(
                  labelText: 'Asignar a usuario',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                hint: const Text('Selecciona un usuario'),
                items: widget.users.map((user) {
                  return DropdownMenuItem(
                    value: user.uid,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF667eea),
                          child: Text(
                            user.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                validator: FormValidators.validateRequired,
                onChanged: (value) {
                  setState(() => _selectedUserId = value);
                },
              ),
              const SizedBox(height: 16),

              // Fecha
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de vencimiento',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDate(_selectedDate)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _assignTask,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667eea),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Asignar Tarea'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF667eea),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _assignTask() async {
    if (!_formKey.currentState!.validate() || _selectedUserId == null) {
      UIHelper.showErrorSnackBar(
        context,
        'Por favor completa todos los campos',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Usar fecha con hora por defecto (23:59)
      final dueDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        23,
        59,
      );

      final taskId = await AdminService.assignTaskToUser(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assignedToUserId: _selectedUserId!,
        dueDate: dueDateTime,
      );

      if (!mounted) return;

      if (taskId != null) {
        // Enviar notificación inmediata al usuario asignado
        try {
          final user = widget.users.firstWhere((u) => u.uid == _selectedUserId);
          await NotificationService.showInstantTaskNotification(
            taskTitle: _titleController.text.trim(),
            userName: user.name,
          );
        } catch (e) {
          print('Error enviando notificación instantánea: $e');
        }

        Navigator.pop(context);
        widget.onTaskAssigned();

        UIHelper.showSuccessSnackBar(
          context,
          'Tarea asignada y notificación enviada',
        );
      } else {
        setState(() => _isLoading = false);
        UIHelper.showErrorSnackBar(
          context,
          'Error al asignar tarea. Intenta nuevamente.',
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      UIHelper.showErrorSnackBar(
        context,
        'Error: ${e.toString()}',
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
