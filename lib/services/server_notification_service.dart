import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class ServerNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Verificar y mostrar notificaciones pendientes del servidor
  static Future<void> checkServerNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Obtener notificaciones no leídas del usuario
      final notificationsQuery = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .orderBy('sentAt', descending: true)
          .get();(
          '📨 Verificando notificaciones del servidor: ${notificationsQuery.docs.length} encontradas');

      for (final doc in notificationsQuery.docs) {
        final notification = doc.data();

        // Mostrar notificación local
        await NotificationService.showNotification(
          id: doc.id.hashCode,
          title: notification['title'] ?? 'Notificación',
          body: notification['message'] ?? '',
          payload: 'server_notification_${doc.id}',
        );

        // Marcar como leída
        await doc.reference.update({'read': true});
      }

      // Limpiar notificaciones antiguas (más de 7 días)
      await _cleanOldNotifications();
    } catch (e) {('Error verificando notificaciones del servidor: $e');
    }
  }

  /// Limpiar notificaciones leídas antiguas
  static Future<void> _cleanOldNotifications() async {
    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      final oldNotifications = await _firestore
          .collection('notifications')
          .where('read', isEqualTo: true)
          .where('sentAt', isLessThan: weekAgo)
          .get();

      if (oldNotifications.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in oldNotifications.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();(
            '🧹 Limpiadas ${oldNotifications.docs.length} notificaciones antiguas');
      }
    } catch (e) {('Error limpiando notificaciones antiguas: $e');
    }
  }

  /// Obtener historial de notificaciones del usuario
  static Stream<QuerySnapshot> getNotificationsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Marcar notificación como leída
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {('Error marcando notificación como leída: $e');
    }
  }

  /// Obtener conteo de notificaciones no leídas
  static Future<int> getUnreadCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final query = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .get();

      return query.docs.length;
    } catch (e) {('Error obteniendo conteo de notificaciones: $e');
      return 0;
    }
  }
}
