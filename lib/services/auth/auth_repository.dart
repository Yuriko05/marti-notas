import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Repositorio para la comunicación con Firebase Authentication
/// Maneja todas las operaciones de autenticación con Firebase
class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Stream para conocer el estado de autenticación del usuario
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Método para obtener el usuario actualmente autenticado
  User? get currentUser => _auth.currentUser;

  /// Registrar usuario con email y contraseña en Firebase Auth
  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AuthRepository: Registrando usuario: $email');

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? firebaseUser = result.user;

      if (firebaseUser == null) {
        debugPrint('AuthRepository: Error - No se pudo crear el usuario');
        return null;
      }

      debugPrint('AuthRepository: Usuario creado exitosamente: ${firebaseUser.uid}');
      return firebaseUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthRepository: FirebaseAuth Error al registrar');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthRepository: Error inesperado al registrar: $e');
      rethrow;
    }
  }

  /// Iniciar sesión con email y contraseña
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AuthRepository: Iniciando sesión: $email');

      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? firebaseUser = result.user;

      if (firebaseUser == null) {
        debugPrint('AuthRepository: Error - No hay usuario después de autenticación');
        return null;
      }

      debugPrint('AuthRepository: Autenticación exitosa: ${firebaseUser.uid}');
      return firebaseUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthRepository: FirebaseAuth Error al iniciar sesión');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthRepository: Error inesperado al iniciar sesión: $e');
      rethrow;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('AuthRepository: Sesión cerrada');
    } catch (e) {
      debugPrint('AuthRepository: Error al cerrar sesión: $e');
      rethrow;
    }
  }

  /// Enviar correo para restablecer contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('AuthRepository: Correo de restablecimiento enviado a $email');
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthRepository: Error al enviar correo de restablecimiento');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthRepository: Error inesperado: $e');
      rethrow;
    }
  }

  /// Cambiar contraseña del usuario actual
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final User? user = currentUser;

      if (user == null || user.email == null) {
        debugPrint('AuthRepository: No hay usuario autenticado o falta email');
        return false;
      }

      // Re-autenticar para confirmar la contraseña actual
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Cambiar la contraseña
      await user.updatePassword(newPassword);

      debugPrint('AuthRepository: Contraseña actualizada correctamente');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthRepository: Error al cambiar contraseña: ${e.code}');
      debugPrint('Message: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('AuthRepository: Error inesperado al cambiar contraseña: $e');
      return false;
    }
  }

  /// Eliminar cuenta de usuario (requiere re-autenticación)
  Future<bool> deleteAccount(String password) async {
    try {
      final User? user = currentUser;

      if (user == null || user.email == null) {
        debugPrint('AuthRepository: No hay usuario autenticado o falta email');
        return false;
      }

      // Re-autenticar para confirmar la identidad
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      // Eliminar cuenta de Authentication
      await user.delete();

      debugPrint('AuthRepository: Cuenta eliminada correctamente');
      return true;
    } catch (e) {
      debugPrint('AuthRepository: Error al eliminar cuenta: $e');
      return false;
    }
  }

  /// Comprobar si existe un usuario con el email proporcionado
  Future<bool> checkIfUserExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      debugPrint('AuthRepository: Error al verificar existencia de usuario: $e');
      return false;
    }
  }

  /// Generar correo fake basado en el nombre del usuario
  String generateFakeEmail(String name) {
    const String fakeDomain = '@app.local';
    
    // Limpiar el nombre: minúsculas, sin espacios, caracteres especiales
    String cleanName = name
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    return '$cleanName$fakeDomain';
  }
}
