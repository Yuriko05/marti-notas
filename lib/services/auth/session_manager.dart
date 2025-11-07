import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'auth_repository.dart';
import 'user_repository.dart';
import '../notification_service.dart';

/// Gestor de sesión que coordina AuthRepository y UserRepository
/// Maneja la lógica de negocio de autenticación y gestión de usuarios
class SessionManager {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  // Lista de emails que pueden iniciar sesión solo con Auth (sin depender
  // de tener un perfil en Firestore). Útil para administradores iniciales.
  static const List<String> _authOnlyAdminEmails = [
    'admin@gmail.com',
  ];

  String _normalizeNameForUsername(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

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
        username: _normalizeNameForUsername(email.split('@')[0]),
        hasPassword: true,
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
        debugPrint('SessionManager: Usuario sin perfil en Firestore.');

        // Si el email está en la lista de administradores que pueden
        // autenticarse solo con Auth, devolvemos un UserModel temporal con
        // role 'admin' sin bloquear la ejecución en creación de Firestore.
        final emailLower = (firebaseUser.email ?? '').toLowerCase();
        if (_authOnlyAdminEmails.contains(emailLower)) {
          debugPrint('SessionManager: Email pertenece a admin auth-only. Creando modelo temporal.');

          final tempModel = UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'Administrador',
            role: 'admin',
            username: _normalizeNameForUsername((firebaseUser.email ?? '').split('@')[0]),
            hasPassword: true,
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );

          // Fire-and-forget: crear perfil en Firestore pero no bloquear login
          _userRepository.createUserProfile(tempModel).then((_) {
            debugPrint('SessionManager: Perfil admin creado en Firestore en background');
          }).catchError((e) {
            debugPrint('SessionManager: Error creando perfil admin en background: $e');
          });

          userModel = tempModel;
        } else {
          debugPrint('SessionManager: Usuario sin perfil en Firestore. Creando perfil por defecto...');

          userModel = UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'Usuario',
            role: 'normal',
            username: _normalizeNameForUsername((firebaseUser.email ?? '').split('@')[0]),
            hasPassword: true,
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );

          await _userRepository.createUserProfile(userModel);
        }
      } else {
        // 4. Actualizar última fecha de login
        await _userRepository.updateLastLogin(firebaseUser.uid);
      }

      debugPrint('SessionManager: Login exitoso: ${userModel.name} (${userModel.role})');

      // Registrar token FCM para la sesión actual (array en Firestore)
      try {
        await NotificationService.registerCurrentDeviceToken();
      } catch (e) {
        debugPrint('SessionManager: Error registrando token FCM en login: $e');
      }

      // Configurar notificaciones locales y verificaciones al login
      try {
        await NotificationService.setupLoginNotifications();
      } catch (e) {
        debugPrint('SessionManager: Error configurando notificaciones al login: $e');
      }

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
    // Guardar admin actual
    final currentAdminUser = _authRepository.currentUser;
    String? adminEmail;
    
    try {
      // 1. Verificar que el nombre no esté en uso
      final existingUser = await _userRepository.findUserByName(name);
      if (existingUser != null) {
        debugPrint('SessionManager: Ya existe un usuario con el nombre: $name');
        return null;
      }

      // 2. Si hay un admin logueado, guardar su email temporalmente
      if (currentAdminUser != null) {
        adminEmail = currentAdminUser.email;
        debugPrint('SessionManager: Admin actual guardado: $adminEmail');
      }

      // 3. Generar correo fake
      final String fakeEmail = _authRepository.generateFakeEmail(name);
      debugPrint('SessionManager: Correo fake generado: $fakeEmail');

      // 4. Crear usuario en Firebase Authentication
      final User? firebaseUser =
          await _authRepository.registerWithEmailAndPassword(
        email: fakeEmail,
        password: password,
      );

      if (firebaseUser == null) {
        return null;
      }

      final newUserId = firebaseUser.uid;

      // 5. Guardar información en Firestore
      final UserModel userModel = UserModel(
        uid: newUserId,
        email: fakeEmail,
        name: name,
        role: role,
        username: _normalizeNameForUsername(name),
        hasPassword: true,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _userRepository.createUserProfile(userModel);

      debugPrint('SessionManager: Usuario creado exitosamente: $name ($newUserId)');

      // 6. Cerrar sesión del usuario recién creado
      await _authRepository.signOut();

      // 7. Nota: Firebase Auth cierra la sesión automáticamente
      // El admin necesitará volver a iniciar sesión manualmente
      debugPrint('SessionManager: ⚠️ Admin deslogueado. Debe volver a iniciar sesión.');

      return newUserId;
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
      final trimmedName = name.trim();

      // 1) Para evitar usar emails "fake", resolvemos primero el email real
      //    consultando Firestore por username/name. Si no hay perfil, fallamos
      //    y devolvemos null. Esto exige permisos de lectura en la colección
      //    `users` (o usar una Cloud Function segura para resolver username->email).
      debugPrint('SessionManager: Buscando perfil por nombre/username: $trimmedName');
      UserModel? userProfileByName;
      try {
        userProfileByName = await _userRepository.findUserByName(trimmedName);
      } catch (err) {
        debugPrint('SessionManager: Error leyendo Firestore al buscar usuario: $err');
        // Re-lanzar para que la UI o logs muestren el error (ej. permission-denied)
        rethrow;
      }
      if (userProfileByName == null) {
        debugPrint('SessionManager: No se encontró perfil para el nombre: $trimmedName');
        return null;
      }

      if (userProfileByName.email.trim().isEmpty) {
        debugPrint('SessionManager: Perfil encontrado pero email vacío para: $trimmedName');
        return null;
      }

      final String realEmail = userProfileByName.email;
      debugPrint('SessionManager: Email resuelto desde Firestore: $realEmail. Intentando login...');

      // 2) Intentar login usando el email real obtenido de Firestore
      final User? firebaseUser = await _authRepository.signInWithEmailAndPassword(
        email: realEmail,
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
    // Intentar eliminar el token del dispositivo actual antes de cerrar sesión
    try {
      await NotificationService.removeCurrentDeviceToken();
    } catch (e) {
      debugPrint('SessionManager: Error eliminando token FCM antes de signOut: $e');
    }

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
          username: _normalizeNameForUsername(name),
          hasPassword: true,
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
