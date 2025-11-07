import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/history_event.dart';
import '../../models/task_model.dart';
import '../../services/history_service.dart';

class TaskHistoryPanel extends StatelessWidget {
  final TaskModel? task;
  final VoidCallback? onOpenFullScreen;

  const TaskHistoryPanel({super.key, required this.task, this.onOpenFullScreen});

  @override
  Widget build(BuildContext context) {
    if (task == null) {
      return _buildEmptyState(
        context,
        'Selecciona una tarea para ver el historial de cambios.',
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: isMobile ? double.infinity : 340,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isMobile 
            ? const BorderRadius.vertical(top: Radius.circular(16))
            : BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: isMobile 
          ? EdgeInsets.zero
          : const EdgeInsets.only(right: 20, top: 16, bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Historial',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isMobile)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '• ${task!.title}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: 'task_history/${task!.id}/events',
                    child: const Icon(Icons.history, size: 20, color: Colors.grey),
                  ),
                  if (onOpenFullScreen != null)
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 20),
                      tooltip: 'Abrir historial en pantalla completa',
                      onPressed: onOpenFullScreen,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<HistoryEvent>>(
              stream: HistoryService.streamEvents(task!.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildEmptyState(
                    context,
                    'Error al cargar historial: ${snapshot.error}',
                  );
                }

                final events = snapshot.data ?? [];
                if (events.isEmpty) {
                  return _buildEmptyState(
                    context,
                    'Aún no hay eventos registrados para esta tarea.',
                  );
                }

                return ListView.separated(
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _buildEventTile(event);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEventTile(HistoryEvent event) {
    final timestamp = event.timestamp;
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final payload = event.payload;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildActionChip(event.action),
            const Spacer(),
            Text(
              timestamp != null ? formatter.format(timestamp) : 'Sin fecha',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (event.actorUid != null)
          Text(
            'Actor: ${event.actorUid}${event.actorRole != null ? ' (${event.actorRole})' : ''}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        if (payload.isNotEmpty) ...[
          const SizedBox(height: 6),
          _buildPayloadPreview(payload),
        ],
      ],
    );
  }

  Widget _buildActionChip(String action) {
    final normalized = action.replaceAll('_', ' ').toUpperCase();
    Color bgColor;
    switch (action) {
      case 'assign':
        bgColor = const Color(0xFF00B894);
        break;
      case 'update':
      case 'update_personal':
        bgColor = const Color(0xFF0984E3);
        break;
      case 'delete':
      case 'delete_personal':
        bgColor = const Color(0xFFD63031);
        break;
      case 'complete':
      case 'confirm':
        bgColor = const Color(0xFF6C5CE7);
        break;
      case 'reject':
        bgColor = const Color(0xFFE17055);
        break;
      case 'read':
        bgColor = const Color(0xFF636E72);
        break;
      default:
        bgColor = const Color(0xFF2D3436);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        normalized,
        style: TextStyle(
          color: bgColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPayloadPreview(Map<String, dynamic> payload) {
    final buffer = <Widget>[];

    if (payload.containsKey('reason')) {
      buffer.add(_buildPayloadRow('Motivo', payload['reason']));
    }
    if (payload.containsKey('notes')) {
      buffer.add(_buildPayloadRow('Notas', payload['notes']));
    }

    if (payload.containsKey('after')) {
      final after = payload['after'];
      if (after is Map<String, dynamic>) {
        if (after.containsKey('status')) {
          buffer.add(_buildPayloadRow('Estado', after['status']));
        }
        if (after.containsKey('assignedTo')) {
          buffer.add(_buildPayloadRow('Asignado a', after['assignedTo']));
        }
        if (after.containsKey('dueDate')) {
          buffer.add(_buildPayloadRow('Vence', after['dueDate'].toString()));
        }
      }
    }

    if (buffer.isEmpty) {
      buffer.add(
        Text(
          payload.toString(),
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: buffer,
    );
  }

  Widget _buildPayloadRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11, color: Color(0xFF2D3436)),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value?.toString() ?? '—'),
          ],
        ),
      ),
    );
  }
}
