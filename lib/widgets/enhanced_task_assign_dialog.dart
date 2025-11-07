import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';

/// Diálogo mejorado para crear y asignar tareas con archivos y prioridad
class EnhancedTaskAssignDialog extends StatefulWidget {
  final List<UserModel> users;
  final VoidCallback onSuccess;

  const EnhancedTaskAssignDialog({
    Key? key,
    required this.users,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<EnhancedTaskAssignDialog> createState() => _EnhancedTaskAssignDialogState();
}

class _EnhancedTaskAssignDialogState extends State<EnhancedTaskAssignDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _linkController = TextEditingController();
  
  String? _selectedUserId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 23, minute: 59);
  String _selectedPriority = 'medium';
  final List<String> _initialLinks = [];
  final List<String> _initialAttachmentUrls = [];
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _uploadImage(ImageSource source) async {
    if (_initialAttachmentUrls.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo 5 archivos permitidos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final url = await StorageService.uploadImage(
        source: source,
        taskId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (url != null) {
        setState(() {
          _initialAttachmentUrls.add(url);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagen subida correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _uploadFile() async {
    if (_initialAttachmentUrls.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo 5 archivos permitidos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final url = await StorageService.uploadFile(
        taskId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (url != null) {
        setState(() {
          _initialAttachmentUrls.add(url);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Archivo subido correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir archivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _initialAttachmentUrls.removeAt(index);
    });
  }

  void _addLink() {
    final link = _linkController.text.trim();
    if (link.isNotEmpty) {
      if (Uri.tryParse(link)?.hasAbsolutePath ?? false) {
        setState(() {
          _initialLinks.add(link);
          _linkController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor ingresa una URL válida'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _removeLink(int index) {
    setState(() {
      _initialLinks.removeAt(index);
    });
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar fuente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _uploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _uploadImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un usuario')),
      );
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Combinar fecha y hora seleccionadas
    final dueDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final taskId = await AdminService.assignTaskToUser(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      assignedToUserId: _selectedUserId!,
      dueDate: dueDateTime,
      priority: _selectedPriority,
      initialAttachments: _initialAttachmentUrls,
      initialLinks: _initialLinks,
      initialInstructions: _instructionsController.text.trim().isEmpty
          ? null
          : _instructionsController.text.trim(),
    );

    if (!context.mounted) return;
    navigator.pop();

    if (taskId != null) {
      // Enviar notificación
      try {
        await NotificationService.showInstantTaskNotification(
          taskTitle: _titleController.text.trim(),
          userName: widget.users.firstWhere((u) => u.uid == _selectedUserId).name,
        );
      } catch (e) {
        // Silently fail notification
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Tarea creada correctamente')),
      );

      widget.onSuccess();
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Error al crear la tarea')),
      );
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.arrow_downward;
      default:
        return Icons.help;
    }
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
        return 'Desconocida';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Tarea', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'El título es requerido' : null,
                ),
                const SizedBox(height: 16),

                // Descripción
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'La descripción es requerida' : null,
                ),
                const SizedBox(height: 16),

                // Usuario
                DropdownButtonFormField<String>(
                  value: _selectedUserId,
                  decoration: const InputDecoration(
                    labelText: 'Asignar a *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: widget.users.map((user) {
                    return DropdownMenuItem(
                      value: user.uid,
                      child: Text(user.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedUserId = value);
                  },
                  validator: (value) => value == null ? 'Selecciona un usuario' : null,
                ),
                const SizedBox(height: 16),

                // Prioridad
                const Text(
                  'Prioridad *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['low', 'medium', 'high'].map((priority) {
                    final isSelected = _selectedPriority == priority;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getPriorityIcon(priority),
                                size: 16,
                                color: isSelected ? Colors.white : _getPriorityColor(priority),
                              ),
                              const SizedBox(width: 4),
                              Text(_getPriorityLabel(priority)),
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: _getPriorityColor(priority),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedPriority = priority);
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Fecha y hora de vencimiento
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Fecha de vencimiento', style: TextStyle(fontSize: 13)),
                        subtitle: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        leading: const Icon(Icons.calendar_today, color: Colors.blue),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        tileColor: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hora', style: TextStyle(fontSize: 13)),
                        subtitle: Text(
                          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        leading: const Icon(Icons.access_time, color: Colors.green),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (picked != null) {
                            setState(() => _selectedTime = picked);
                          }
                        },
                        tileColor: Colors.green.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Divider(),
                const SizedBox(height: 8),

                // Instrucciones adicionales
                const Text(
                  'Instrucciones Adicionales (Opcional)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _instructionsController,
                  decoration: const InputDecoration(
                    hintText: 'Agrega instrucciones detalladas para el usuario...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Enlaces
                const Text(
                  'Enlaces de Referencia (Opcional)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _linkController,
                        decoration: const InputDecoration(
                          hintText: 'https://ejemplo.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blue),
                      onPressed: _addLink,
                      tooltip: 'Agregar enlace',
                    ),
                  ],
                ),
                if (_initialLinks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...List.generate(_initialLinks.length, (index) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.link, size: 20),
                      title: Text(
                        _initialLinks[index],
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () => _removeLink(index),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 16),

                // Archivos adjuntos
                const Text(
                  'Archivos e Imágenes (Opcional)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : _showImageSourceDialog,
                        icon: const Icon(Icons.image),
                        label: const Text('Subir Foto'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : _uploadFile,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Subir Archivo'),
                      ),
                    ),
                  ],
                ),
                if (_isUploading) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 4),
                  const Text(
                    'Subiendo archivo...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                if (_initialAttachmentUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Archivos adjuntos:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_initialAttachmentUrls.length, (index) {
                      final url = _initialAttachmentUrls[index];
                      final fileName = url.split('/').last.split('?').first;
                      final isImage = fileName.toLowerCase().endsWith('.jpg') ||
                          fileName.toLowerCase().endsWith('.jpeg') ||
                          fileName.toLowerCase().endsWith('.png');

                      return Chip(
                        avatar: Icon(
                          isImage ? Icons.image : Icons.insert_drive_file,
                          size: 18,
                        ),
                        label: Text(
                          fileName.length > 20
                              ? '${fileName.substring(0, 20)}...'
                              : fileName,
                          style: const TextStyle(fontSize: 11),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _removeAttachment(index),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isUploading ? null : _createTask,
          icon: const Icon(Icons.check),
          label: const Text('Crear Tarea'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
