import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'task_completion_dialog.dart';

class TaskPreviewDialog extends StatefulWidget {
  final TaskModel task;
  final bool showActions;

  const TaskPreviewDialog({
    super.key,
    required this.task,
    this.showActions = true,
  });

  /// Helper para abrir la vista previa. En móviles presenta una pantalla completa,
  /// en pantallas grandes presenta un diálogo modal centrado.
  static Future<void> open(BuildContext context, TaskModel task,
      {bool showActions = true}) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(task.title)),
          body: SafeArea(
              child: TaskPreviewDialog(task: task, showActions: showActions)),
        ),
      ));
    }

    return showDialog(
      context: context,
      builder: (context) =>
          TaskPreviewDialog(task: task, showActions: showActions),
    );
  }

  @override
  State<TaskPreviewDialog> createState() => _TaskPreviewDialogState();
}

class _TaskPreviewDialogState extends State<TaskPreviewDialog> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _markReadIfNeeded();
  }

  Future<void> _markReadIfNeeded() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Solo marcar como leída si el usuario actual es el asignado
      if (currentUser.uid == widget.task.assignedTo) {
        await TaskService.markTaskAsRead(widget.task.id);
      }
    } catch (e) {
      // Ignorar errores menores al marcar como leído
    }
  }

  Future<void> _handleStartTask() async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);
    try {
      await TaskService.startTask(widget.task.id);
      if (mounted) {
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Tarea iniciada')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCompleteTask() async {
    // Si es tarea personal, completar directamente sin evidencias
    if (widget.task.isPersonal) {
      final messenger = ScaffoldMessenger.of(context);

      setState(() => _isLoading = true);
      try {
        await TaskService.completeTask(widget.task.id);
        if (mounted) {
          Navigator.of(context).pop();
          messenger.showSnackBar(
            const SnackBar(
              content: Text('✅ Tarea personal completada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    // Si NO es personal, abrir diálogo de evidencias
    final messenger = ScaffoldMessenger.of(context);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => TaskCompletionDialog(
        taskId: widget.task.id,
        onSubmit: (comment, links, attachments) async {
          setState(() => _isLoading = true);
          try {
            await TaskService.submitTaskForReview(
              taskId: widget.task.id,
              comment: comment,
              links: links,
              attachments: attachments,
            );
            Navigator.of(dialogContext)
                .pop(true); // Retorna true para cerrar el preview también
            messenger.showSnackBar(
              const SnackBar(
                content: Text('✅ Tarea enviada para revisión del administrador'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        },
      ),
    );

    // Cerrar TaskPreviewDialog también después de enviar
    if (result == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleCancelTask() async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);
    try {
      await TaskService.revertTaskStatus(widget.task.id);
      if (mounted) {
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Estado revertido')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // !! CAMBIO: Lógica de estado actualizada
    final bool isPending = widget.task.status == 'pending';
    final bool isPendingReview = widget.task.status == 'pending_review';

    // "Rechazada" es 'in_progress' CON un comentario
    final bool isRejected = (widget.task.status == 'in_progress' &&
        widget.task.reviewComment != null &&
        widget.task.reviewComment!.isNotEmpty);

    // "En Progreso" es 'in_progress' SIN un comentario
    final bool isInProgress =
        (widget.task.status == 'in_progress' && !isRejected);

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

              // Comentario del Admin (si existe) - DESTACADO AL INICIO
              // !! CAMBIO: Esta función ahora maneja todos los casos
              if (widget.task.reviewComment != null &&
                  widget.task.reviewComment!.isNotEmpty)
                _buildAdminCommentAlert(),

              // Prioridad
              _buildPrioritySection(),
              const SizedBox(height: 16),

              // Descripción
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.task.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      // Instrucciones iniciales del admin
                      if (widget.task.initialInstructions != null &&
                          widget.task.initialInstructions!.isNotEmpty)
                        _buildInstructionsSection(),

                      // Archivos adjuntos iniciales del admin
                      if (widget.task.initialAttachments.isNotEmpty)
                        _buildInitialAttachmentsSection(),

                      // Enlaces de referencia del admin
                      if (widget.task.initialLinks.isNotEmpty)
                        _buildInitialLinksSection(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // !! CAMBIO: Se eliminó el bloque 'if (isRejected ...)' de aquí
              // porque _buildAdminCommentAlert() ya lo maneja.

              // Botones de acción
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (widget.showActions)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    // Botón Cancelar (revertir estado)
                    if (isInProgress || isRejected) // Se puede cancelar si está en progreso o rechazada
                      TextButton.icon(
                        onPressed: _handleCancelTask,
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text('Cancelar Estado'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),

                    // Botón Realizar (solo si está pendiente)
                    if (isPending)
                      ElevatedButton.icon(
                        onPressed: _handleStartTask,
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Realizar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),

                    // Botón Completado (solo si está en progreso normal)
                    if (isInProgress) // !! CAMBIO: Ya no se muestra si está rechazada
                      ElevatedButton.icon(
                        onPressed: _handleCompleteTask,
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Marcar Completada'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),

                    // Botón Corregir y Re-enviar (solo si fue rechazada)
                    if (isRejected) // !! CAMBIO: Usa la nueva variable
                      ElevatedButton.icon(
                        onPressed: _handleCompleteTask,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Corregir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFf7b733),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                  ],
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySection() {
    Map<String, dynamic> priorityInfo;

    switch (widget.task.priority) {
      case 'high':
        priorityInfo = {
          'color': const Color(0xFFfc4a1a),
          'icon': Icons.priority_high,
          'text': 'Prioridad Alta',
        };
        break;
      case 'low':
        priorityInfo = {
          'color': const Color(0xFF43e97b),
          'icon': Icons.arrow_downward,
          'text': 'Prioridad Baja',
        };
        break;
      case 'medium':
      default:
        priorityInfo = {
          'color': const Color(0xFFf7b733),
          'icon': Icons.remove,
          'text': 'Prioridad Media',
        };
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (priorityInfo['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (priorityInfo['color'] as Color).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            priorityInfo['icon'] as IconData,
            color: priorityInfo['color'] as Color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            priorityInfo['text'] as String,
            style: TextStyle(
              fontSize: 14,
              color: priorityInfo['color'] as Color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Instrucciones del Admin',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.task.initialInstructions!,
            style: TextStyle(
              color: Colors.blue.shade900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialAttachmentsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file,
                  size: 18, color: Colors.purple.shade700),
              const SizedBox(width: 8),
              Text(
                'Archivos del Admin',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.task.initialAttachments.map((url) {
              final fileName = url.split('/').last.split('?').first;
              final isImage = fileName.toLowerCase().endsWith('.jpg') ||
                  fileName.toLowerCase().endsWith('.jpeg') ||
                  fileName.toLowerCase().endsWith('.png');

              return InkWell(
                onTap: () => _openUrl(url),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isImage ? Icons.image : Icons.insert_drive_file,
                        size: 16,
                        color: Colors.purple.shade700,
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          fileName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple.shade900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.open_in_new,
                        size: 14,
                        color: Colors.purple.shade500,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialLinksSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, size: 18, color: Colors.teal.shade700),
              const SizedBox(width: 8),
              Text(
                'Enlaces de Referencia',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.task.initialLinks.map((link) {
              return InkWell(
                onTap: () => _openUrl(link),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link, size: 14, color: Colors.teal.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          link,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.teal.shade900,
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.open_in_new,
                          size: 14, color: Colors.teal.shade500),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se puede abrir el enlace')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir enlace: $e')),
        );
      }
    }
  }

  // !! CAMBIO: Esta función fue reemplazada por completo
  Widget _buildAdminCommentAlert() {
    // NUEVA LÓGICA:
    // Detectar si la tarea está rechazada (en progreso + comentario)
    final isRejected = (widget.task.status == 'in_progress' &&
        widget.task.reviewComment != null &&
        widget.task.reviewComment!.isNotEmpty);

    // Detectar si es un comentario de aprobación (completada, confirmada o en revisión)
    final isApproved = (widget.task.status == 'completed' ||
        widget.task.status == 'confirmed' ||
        widget.task.status == 'pending_review');

    final Color color;
    final String title;
    final IconData icon;

    if (isRejected) {
      color = const Color(0xFFfc4a1a);
      title = '❌ Tarea Rechazada por el Admin';
      icon = Icons.cancel;
    } else if (isApproved) {
      color = const Color(0xFF667eea);
      title = '✅ Comentario del Admin';
      icon = Icons.check_circle;
    } else {
      // Si no es ninguno (ej. una tarea en progreso sin comentario), no mostrar nada
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote,
                  color: color.withOpacity(0.5),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.task.reviewComment!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isRejected) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFf7b733).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFf7b733),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: const Color(0xFFf7b733),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Por favor corrige y vuelve a enviar usando el botón de abajo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}