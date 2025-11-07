import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryEvent {
  final String id;
  final String action;
  final String? actorUid;
  final String? actorRole;
  final DateTime? timestamp;
  final Map<String, dynamic> payload;

  HistoryEvent({
    required this.id,
    required this.action,
    required this.actorUid,
    required this.actorRole,
    required this.timestamp,
    required this.payload,
  });

  factory HistoryEvent.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return HistoryEvent(
      id: doc.id,
      action: (data['action'] as String?) ?? 'unknown',
      actorUid: data['actorUid'] as String?,
      actorRole: data['actorRole'] as String?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      payload: (data['payload'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }
}
