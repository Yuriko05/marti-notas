import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth/session_manager.dart';

/// Provider para el manejo de estado de autenticación
/// Centraliza toda la lógica de autenticación y notifica cambios a la UI
class AuthProvider with ChangeNotifier {
  final SessionManager _sessionManager;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({SessionManager? sessionManager})
      : _sessionManager = sessionManager ?? SessionManager() {
    // Inicializar escuchando cambios de autenticación
    _initAuthListener();
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Inicializar listener de cambios de autenticación
  void _initAuthListener() {
    _sessionManager.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        // Usuario autenticado, cargar perfil
        await _loadUserProfile();
      } else {
        // No hay usuario autenticado
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  /// Cargar perfil del usuario actual
  Future<void> _loadUserProfile() async {
    try {
      _currentUser = await _sessionManager.getCurrentUserProfile();
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider: Error al cargar perfil: $e');
      _errorMessage = 'Error al cargar perfil de usuario';
      notifyListeners();
    }
  }

  /// Registro con email y contraseña
  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String role = 'normal',
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await _sessionManager.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      _isLoading = false;

      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Error al registrar usuario';
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getAuthErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Login con email y contraseña
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await _sessionManager.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _isLoading = false;

      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Credenciales inválidas';
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getAuthErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Login con nombre y contraseña
  Future<bool> signInWithNameAndPassword({
    required String name,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await _sessionManager.signInWithNameAndPassword(
        name: name,
        password: password,
      );

      _isLoading = false;

      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Nombre o contraseña incorrectos';
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getAuthErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Registro con nombre y contraseña
  Future<String?> registerWithNameAndPassword({
    required String name,
    required String password,
    String role = 'normal',
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userId = await _sessionManager.registerWithNameAndPassword(
        name: name,
        password: password,
        role: role,
      );

      _isLoading = false;
      notifyListeners();

      if (userId == null) {
        _errorMessage = 'El nombre ya está en uso';
      }

      return userId;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al registrar: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _sessionManager.signOut();

      _currentUser = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al cerrar sesión';
      notifyListeners();
    }
  }

  /// Cambiar contraseña
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _sessionManager.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      _isLoading = false;

      if (!success) {
        _errorMessage = 'No se pudo cambiar la contraseña';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al cambiar contraseña: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Actualizar perfil
  Future<bool> updateProfile({
    required String userId,
    String? name,
    String? role,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _sessionManager.updateUserProfile(
        userId: userId,
        name: name,
        role: role,
      );

      if (success && userId == _currentUser?.uid) {
        // Si actualizamos el perfil del usuario actual, recargar
        await _loadUserProfile();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al actualizar perfil: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Enviar correo de restablecimiento de contraseña
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _sessionManager.sendPasswordResetEmail(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al enviar correo: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Eliminar cuenta
  Future<bool> deleteAccount(String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _sessionManager.deleteAccount(password);

      if (success) {
        _currentUser = null;
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al eliminar cuenta: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Crear usuario como administrador
  Future<String?> createUserAsAdmin({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userId = await _sessionManager.createUserAsAdmin(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      _isLoading = false;

      if (userId == null) {
        _errorMessage = 'No se pudo crear el usuario';
      }

      notifyListeners();
      return userId;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al crear usuario: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Eliminar usuario como administrador
  Future<bool> deleteUserAsAdmin(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _sessionManager.deleteUserAsAdmin(userId: userId);

      _isLoading = false;

      if (!success) {
        _errorMessage = 'No se pudo eliminar el usuario';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al eliminar usuario: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Obtener mensaje de error legible desde FirebaseAuthException
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es demasiado débil';
      case 'email-already-in-use':
        return 'El email ya está en uso';
      case 'invalid-email':
        return 'El email no es válido';
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      case 'user-disabled':
        return 'Usuario deshabilitado';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      default:
        return e.message ?? 'Error de autenticación';
    }
  }
}
