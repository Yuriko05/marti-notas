import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'auth/session_manager.dart';

/// Clase de compatibilidad para mantener la misma interfaz que AuthService original
/// Delega todas las operaciones a SessionManager
///
/// NOTA: Este archivo mantiene compatibilidad con el código existente
/// mientras se realiza la migración a la nueva arquitectura con Provider
class AuthService {
  static final SessionManager _sessionManager = SessionManager();

  /// Stream para conocer el estado de autenticación del usuario
  static Stream<User?> get authStateChanges => _sessionManager.authStateChanges;

  /// Método para obtener el usuario actualmente autenticado
  static User? get currentUser => _sessionManager.currentUser;

  /// Registro de usuario con email y contraseña
  static Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String role = 'normal',
  }) async {
    return await _sessionManager.registerWithEmailAndPassword(
      email: email,
      password: password,
      name: name,
      role: role,
    );
  }

  /// Inicio de sesión con email y contraseña
  static Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _sessionManager.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Obtener el perfil del usuario actual desde Firestore
  static Future<UserModel?> getCurrentUserProfile() async {
    return await _sessionManager.getCurrentUserProfile();
  }

  /// Stream para escuchar cambios en el perfil del usuario actual
  static Stream<UserModel?> get userProfileStream =>
      _sessionManager.userProfileStream;

  /// Cerrar sesión
  static Future<void> signOut() async {
    await _sessionManager.signOut();
  }

  /// Enviar correo para restablecer contraseña
  static Future<void> sendPasswordResetEmail(String email) async {
    await _sessionManager.sendPasswordResetEmail(email);
  }

  /// Actualizar perfil de usuario (nombre o rol)
  static Future<bool> updateUserProfile({
    required String userId,
    String? name,
    String? role,
  }) async {
    return await _sessionManager.updateUserProfile(
      userId: userId,
      name: name,
      role: role,
    );
  }

  /// Verificar si el usuario actual tiene permisos de administrador
  static Future<bool> isCurrentUserAdmin() async {
    return await _sessionManager.isCurrentUserAdmin();
  }

  /// Cambiar contraseña del usuario actual
  static Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    return await _sessionManager.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Eliminar cuenta de usuario (requiere re-autenticación)
  static Future<bool> deleteAccount(String password) async {
    return await _sessionManager.deleteAccount(password);
  }

  /// Comprobar si existe un usuario con el email proporcionado
  static Future<bool> checkIfUserExists(String email) async {
    // Este método no está en SessionManager, pero podemos agregarlo si es necesario
    // Por ahora, retornamos false
    return false;
  }

  /// Eliminar usuario desde el panel de administración
  static Future<bool> deleteUserAsAdmin({
    required String userId,
    required String userEmail,
  }) async {
    return await _sessionManager.deleteUserAsAdmin(userId: userId);
  }

  /// Crear un nuevo usuario desde el panel de administración
  static Future<String?> createUserAsAdmin({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    return await _sessionManager.createUserAsAdmin(
      email: email,
      password: password,
      name: name,
      role: role,
    );
  }

  /// Registro simplificado con solo nombre y contraseña
  static Future<String?> registerWithNameAndPassword({
    required String name,
    required String password,
    String role = 'normal',
  }) async {
    return await _sessionManager.registerWithNameAndPassword(
      name: name,
      password: password,
      role: role,
    );
  }

  /// Login simplificado con nombre y contraseña
  static Future<UserModel?> signInWithNameAndPassword({
    required String name,
    required String password,
  }) async {
    return await _sessionManager.signInWithNameAndPassword(
      name: name,
      password: password,
    );
  }

  /// Verificar si un nombre de usuario ya existe
  static Future<bool> isNameTaken(String name) async {
    return await _sessionManager.isNameTaken(name);
  }
}
