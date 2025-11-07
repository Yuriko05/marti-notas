import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/history_event.dart';

class HistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registra un evento de auditoría para una tarea.
  /// Escribe en dos ubicaciones para compatibilidad:
  /// - tasks/{taskId}/history
  /// - task_history/{taskId}/events
  static Future<void> recordEvent({
    required String taskId,
    required String action,
    String? actorUid,
    String? actorRole,
    Map<String, dynamic>? payload,
  }) async {
    final event = {
      'action': action,
      'actorUid': actorUid,
      'actorRole': actorRole,
      'timestamp': FieldValue.serverTimestamp(),
      'payload': payload ?? {},
    };

    try {
      // Escribir en tasks/{taskId}/history (legacy)
      try {
        await _firestore.collection('tasks').doc(taskId).collection('history').add(event);
      } catch (e) {
        // ignore: avoid_print
        print('Warning: failed to write legacy history for $taskId: $e');
      }

      // Escribir en task_history/{taskId}/events (nuevo)
      await _firestore.collection('task_history').doc(taskId).collection('events').add(event);
    } catch (e) {
      // ignore: avoid_print
      print('Error escribiendo history para $taskId: $e');
    }
  }

  /// Obtiene un stream de eventos de auditoría para la tarea.
  /// Lee de la colección nueva `task_history/{taskId}/events` con orderBy timestamp DESC.
  static Stream<List<HistoryEvent>> streamEvents(String taskId, {int limit = 50}) {
    return _firestore
        .collection('task_history')
        .doc(taskId)
        .collection('events')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HistoryEvent.fromFirestore(doc))
            .toList());
  }
}
