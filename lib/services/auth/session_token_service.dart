import 'package:flutter/material.dart';
import '../notification_service.dart';

/// Gestiona el registro y limpieza de tokens FCM asociados a la sesión.
class SessionTokenService {
  /// Acciones posteriores a un login exitoso.
  Future<void> handlePostLogin() async {
    try {
      await NotificationService.registerCurrentDeviceToken();
    } catch (e) {
      debugPrint(
          'SessionTokenService: Error registrando token FCM en login: $e');
    }

    try {
      await NotificationService.setupLoginNotifications();
    } catch (e) {
      debugPrint(
          'SessionTokenService: Error configurando notificaciones al login: $e');
    }
  }

  /// Limpia el token del dispositivo antes de cerrar sesión.
  Future<void> handlePreSignOut() async {
    try {
      await NotificationService.removeCurrentDeviceToken();
    } catch (e) {
      debugPrint(
          'SessionTokenService: Error eliminando token FCM antes de signOut: $e');
    }
  }
}
