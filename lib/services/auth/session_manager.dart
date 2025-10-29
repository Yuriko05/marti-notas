import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'auth_repository.dart';
import 'user_repository.dart';

/// Gestor de sesión que coordina AuthRepository y UserRepository
/// Maneja la lógica de negocio de autenticación y gestión de usuarios
class SessionManager {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  SessionManager({
    AuthRepository? authRepository,
    UserRepository? userRepository,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _userRepository = userRepository ?? UserRepository();

  /// Stream para conocer el estado de autenticación
  Stream<User?> get authStateChanges => _authRepository.authStateChanges;

  /// Usuario actual de Firebase Auth
  User? get currentUser => _authRepository.currentUser;

  /// Registro completo: crea usuario en Auth y perfil en Firestore
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String role = 'normal',
  }) async {
    try {
      // 1. Crear usuario en Firebase Authentication
      final User? firebaseUser =
          await _authRepository.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (firebaseUser == null) {
        return null;
      }

      // 2. Crear perfil en Firestore
      final UserModel userModel = UserModel(
        uid: firebaseUser.uid,
        email: email,
        name: name,
        role: role,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _userRepository.createUserProfile(userModel);

      debugPrint('SessionManager: Usuario registrado correctamente: ${userModel.uid}');
      return userModel;
    } catch (e) {
      debugPrint('SessionManager: Error al registrar usuario: $e');
      rethrow;
    }
  }

  /// Login completo: autentica y carga perfil de Firestore
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Autenticar con Firebase Authentication
      final User? firebaseUser =
          await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (firebaseUser == null) {
        return null;
      }

      // 2. Cargar perfil desde Firestore
      UserModel? userModel = await _userRepository.getUserProfile(firebaseUser.uid);

      // 3. Si no existe perfil, crear uno por defecto
      if (userModel == null) {
        debugPrint('SessionManager: Usuario sin perfil en Firestore. Creando...');

        userModel = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ??
              firebaseUser.email?.split('@')[0] ??
              'Usuario',
          role: 'normal',
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );

        await _userRepository.createUserProfile(userModel);
      } else {
        // 4. Actualizar última fecha de login
        await _userRepository.updateLastLogin(firebaseUser.uid);
      }

      debugPrint('SessionManager: Login exitoso: ${userModel.name} (${userModel.role})');
      return userModel;
    } catch (e) {
      debugPrint('SessionManager: Error al iniciar sesión: $e');
      rethrow;
    }
  }

  /// Registro simplificado con nombre y contraseña (genera email fake)
  Future<String?> registerWithNameAndPassword({
    required String name,
    required String password,
    String role = 'normal',
  }) async {
    try {
      // 1. Verificar que el nombre no esté en uso
      final existingUser = await _userRepository.findUserByName(name);
      if (existingUser != null) {
        debugPrint('SessionManager: Ya existe un usuario con el nombre: $name');
        return null;
      }

      // 2. Generar correo fake
      final String fakeEmail = _authRepository.generateFakeEmail(name);
      debugPrint('SessionManager: Correo fake generado: $fakeEmail');

      // 3. Crear usuario en Firebase Authentication
      final User? firebaseUser =
          await _authRepository.registerWithEmailAndPassword(
        email: fakeEmail,
        password: password,
      );

      if (firebaseUser == null) {
        return null;
      }

      // 4. Guardar información en Firestore
      final UserModel userModel = UserModel(
        uid: firebaseUser.uid,
        email: fakeEmail,
        name: name,
        role: role,
        password: password, // Guardamos la contraseña para mostrar en admin
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _userRepository.createUserProfile(userModel);

      debugPrint('SessionManager: Usuario creado exitosamente: $name (${firebaseUser.uid})');

      // 5. Cerrar sesión del usuario recién creado
      await _authRepository.signOut();

      return firebaseUser.uid;
    } catch (e) {
      debugPrint('SessionManager: Error al registrar usuario con nombre: $e');
      return null;
    }
  }

  /// Login simplificado con nombre y contraseña
  Future<UserModel?> signInWithNameAndPassword({
    required String name,
    required String password,
  }) async {
    try {
      // 1. Generar correo fake basado en el nombre
      final String fakeEmail = _authRepository.generateFakeEmail(name);
      debugPrint('SessionManager: Email fake: $fakeEmail');

      // 2. Intentar hacer login con Firebase Authentication
      final User? firebaseUser =
          await _authRepository.signInWithEmailAndPassword(
        email: fakeEmail,
        password: password,
      );

      if (firebaseUser == null) {
        return null;
      }

      // 3. Cargar el perfil del usuario desde Firestore
      final UserModel? userModel =
          await _userRepository.getUserProfile(firebaseUser.uid);

      if (userModel == null) {
        debugPrint('SessionManager: Usuario sin perfil en Firestore');
        await _authRepository.signOut();
        return null;
      }

      // 4. Actualizar último login
      await _userRepository.updateLastLogin(firebaseUser.uid);

      debugPrint('SessionManager: Login exitoso: ${userModel.name} (${userModel.role})');
      return userModel;
    } catch (e) {
      debugPrint('SessionManager: Error en login con nombre: $e');
      rethrow;
    }
  }

  /// Obtener el perfil del usuario actual
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final User? firebaseUser = currentUser;

      if (firebaseUser == null) {
        debugPrint('SessionManager: No hay usuario autenticado');
        return null;
      }

      return await _userRepository.getUserProfile(firebaseUser.uid);
    } catch (e) {
      debugPrint('SessionManager: Error al obtener perfil: $e');
      return null;
    }
  }

  /// Stream del perfil del usuario actual
  Stream<UserModel?> get userProfileStream {
    final User? user = currentUser;

    if (user == null) {
      return Stream.value(null);
    }

    return _userRepository.getUserProfileStream(user.uid);
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  /// Verificar si el usuario actual es administrador
  Future<bool> isCurrentUserAdmin() async {
    final UserModel? user = await getCurrentUserProfile();
    return user?.isAdmin ?? false;
  }

  /// Cambiar contraseña
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await _authRepository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Eliminar cuenta completa (Auth + Firestore)
  Future<bool> deleteAccount(String password) async {
    try {
      final User? user = currentUser;
      if (user == null) return false;

      // 1. Eliminar de Firestore
      await _userRepository.deleteUserProfile(user.uid);

      // 2. Eliminar de Authentication
      return await _authRepository.deleteAccount(password);
    } catch (e) {
      debugPrint('SessionManager: Error al eliminar cuenta: $e');
      return false;
    }
  }

  /// Actualizar perfil de usuario
  Future<bool> updateUserProfile({
    required String userId,
    String? name,
    String? role,
  }) async {
    return await _userRepository.updateUserProfile(
      userId: userId,
      name: name,
      role: role,
    );
  }

  /// Verificar si un nombre está en uso
  Future<bool> isNameTaken(String name) async {
    final String fakeEmail = _authRepository.generateFakeEmail(name);
    return await _authRepository.checkIfUserExists(fakeEmail);
  }

  /// Enviar correo para restablecer contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    await _authRepository.sendPasswordResetEmail(email);
  }

  /// Crear usuario desde panel de administración
  Future<String?> createUserAsAdmin({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      // Guardar referencia al usuario administrador actual
      final User? adminUser = currentUser;
      if (adminUser == null) {
        debugPrint('SessionManager: No hay un administrador autenticado');
        return null;
      }

      // Verificar si el usuario ya existe
      final userExists = await _authRepository.checkIfUserExists(email);
      if (userExists) {
        debugPrint('SessionManager: El email ya está en uso: $email');
        return null;
      }

      // Crear usuario en Firebase Authentication
      final User? newUser = await _authRepository.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (newUser == null) {
        return null;
      }

      String newUserId = newUser.uid;

      try {
        // Crear el perfil en Firestore
        final UserModel userModel = UserModel(
          uid: newUserId,
          email: email,
          name: name,
          role: role,
          createdAt: DateTime.now(),
        );

        await _userRepository.createUserProfile(userModel);

        // Cerrar sesión del usuario recién creado
        await _authRepository.signOut();

        debugPrint('SessionManager: Usuario creado por admin: $email ($newUserId)');
        return newUserId;
      } catch (e) {
        // Si falla al crear en Firestore, eliminar el usuario de Auth
        await _authRepository.deleteAccount(password);
        debugPrint('SessionManager: Error al crear perfil en Firestore: $e');
        return null;
      }
    } catch (e) {
      debugPrint('SessionManager: Error al crear usuario como admin: $e');
      return null;
    }
  }

  /// Eliminar usuario desde panel de administración
  Future<bool> deleteUserAsAdmin({
    required String userId,
  }) async {
    try {
      // Eliminar de Firestore
      await _userRepository.deleteUserProfile(userId);
      debugPrint('SessionManager: Usuario eliminado desde admin: $userId');
      return true;
    } catch (e) {
      debugPrint('SessionManager: Error al eliminar usuario como admin: $e');
      return false;
    }
  }
}
