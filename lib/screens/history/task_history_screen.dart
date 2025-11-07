import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/history_event.dart';
import '../../models/task_model.dart';
import '../../services/history_service.dart';

/// Pantalla dedicada para visualizar el historial completo de una tarea.
class TaskHistoryScreen extends StatelessWidget {
  final TaskModel task;

  const TaskHistoryScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial: ${task.title}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: 'Copiar ruta task_history/${task.id}/events',
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: 'task_history/${task.id}/events'),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ruta copiada al portapapeles')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<HistoryEvent>>(
        stream: HistoryService.streamEvents(task.id, limit: 100),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error al cargar el historial: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final events = snapshot.data ?? const [];
          if (events.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Aún no hay eventos registrados para esta tarea.'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isLast = index == events.length - 1;
              return _TimelineEntry(event: event, isLast: isLast);
            },
          );
        },
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final HistoryEvent event;
  final bool isLast;

  const _TimelineEntry({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final timestampText = event.timestamp != null ? formatter.format(event.timestamp!) : 'Sin fecha';

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _actionColor(event.action),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.only(top: 4),
                        color: Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ActionChip(action: event.action),
                        const Spacer(),
                        Text(
                          timestampText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (event.actorUid != null)
                      Text(
                        'Actor: ${event.actorUid}${event.actorRole != null ? ' (${event.actorRole})' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (event.payload.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _PayloadPreview(payload: event.payload),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'assign':
        return const Color(0xFF00B894);
      case 'update':
      case 'update_personal':
        return const Color(0xFF0984E3);
      case 'delete':
      case 'delete_personal':
        return const Color(0xFFD63031);
      case 'complete':
      case 'confirm':
        return const Color(0xFF6C5CE7);
      case 'reject':
        return const Color(0xFFE17055);
      case 'read':
        return const Color(0xFF636E72);
      default:
        return const Color(0xFF2D3436);
    }
  }
}

class _ActionChip extends StatelessWidget {
  final String action;

  const _ActionChip({required this.action});

  @override
  Widget build(BuildContext context) {
    final label = action.replaceAll('_', ' ').toUpperCase();
    final color = _actionColor(action);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'assign':
        return const Color(0xFF00B894);
      case 'update':
      case 'update_personal':
        return const Color(0xFF0984E3);
      case 'delete':
      case 'delete_personal':
        return const Color(0xFFD63031);
      case 'complete':
      case 'confirm':
        return const Color(0xFF6C5CE7);
      case 'reject':
        return const Color(0xFFE17055);
      case 'read':
        return const Color(0xFF636E72);
      default:
        return const Color(0xFF2D3436);
    }
  }
}

class _PayloadPreview extends StatelessWidget {
  final Map<String, dynamic> payload;

  const _PayloadPreview({required this.payload});

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];

    if (payload.containsKey('reason')) {
      sections.add(_PayloadRow(label: 'Motivo', value: payload['reason']));
    }
    if (payload.containsKey('notes')) {
      sections.add(_PayloadRow(label: 'Notas', value: payload['notes']));
    }

    final after = payload['after'];
    if (after is Map<String, dynamic>) {
      if (after.containsKey('status')) {
        sections.add(_PayloadRow(label: 'Estado', value: after['status']));
      }
      if (after.containsKey('assignedTo')) {
        sections.add(_PayloadRow(label: 'Asignado a', value: after['assignedTo']));
      }
      if (after.containsKey('dueDate')) {
        sections.add(_PayloadRow(label: 'Vence', value: after['dueDate']));
      }
    }

    if (sections.isEmpty) {
      sections.add(
        Text(
          payload.toString(),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }
}

class _PayloadRow extends StatelessWidget {
  final String label;
  final dynamic value;

  const _PayloadRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Color(0xFF2D3436)),
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
