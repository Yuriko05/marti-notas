import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskPreviewDialog extends StatefulWidget {
  final TaskModel task;

  const TaskPreviewDialog({
    super.key,
    required this.task,
  });

  @override
  State<TaskPreviewDialog> createState() => _TaskPreviewDialogState();
}

class _TaskPreviewDialogState extends State<TaskPreviewDialog> {
  bool _isLoading = false;

  Future<void> _handleStartTask() async {
    setState(() => _isLoading = true);
    try {
      await TaskService.startTask(widget.task.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea iniciada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCompleteTask() async {
    setState(() => _isLoading = true);
    try {
      await TaskService.completeTask(widget.task.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea completada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCancelTask() async {
    setState(() => _isLoading = true);
    try {
      await TaskService.revertTaskStatus(widget.task.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estado revertido')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = widget.task.status == 'pending';
    final isInProgress = widget.task.status == 'in_progress';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título y botón cerrar
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.task.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Descripción
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    widget.task.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botones de acción
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Botón Cancelar (revertir estado)
                    TextButton(
                      onPressed: _handleCancelTask,
                      child: const Text('Cancelar Estado'),
                    ),
                    const SizedBox(width: 8),

                    // Botón Realizar (solo si está pendiente)
                    if (isPending)
                      ElevatedButton.icon(
                        onPressed: _handleStartTask,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Realizar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),

                    // Botón Completado (solo si está en progreso)
                    if (isInProgress)
                      ElevatedButton.icon(
                        onPressed: _handleCompleteTask,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Completado'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
