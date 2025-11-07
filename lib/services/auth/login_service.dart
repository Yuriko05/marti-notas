import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'auth_repository.dart';
import 'user_repository.dart';
import 'username_formatter.dart';

/// Contiene la lógica de autenticación (login) y carga de perfiles.
class LoginService {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final List<String> _authOnlyAdminEmails;

  LoginService({
    required AuthRepository authRepository,
    required UserRepository userRepository,
    List<String>? authOnlyAdminEmails,
  })  : _authRepository = authRepository,
        _userRepository = userRepository,
        _authOnlyAdminEmails =
            authOnlyAdminEmails ?? const <String>['admin@gmail.com'];

  /// Inicia sesión con email/contraseña y garantiza que exista perfil en Firestore.
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final User? firebaseUser = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (firebaseUser == null) {
        return null;
      }

      UserModel? userModel =
          await _userRepository.getUserProfile(firebaseUser.uid);

      if (userModel == null) {
        debugPrint('LoginService: Usuario sin perfil en Firestore.');

        final emailLower = (firebaseUser.email ?? '').toLowerCase();
        if (_authOnlyAdminEmails.contains(emailLower)) {
          debugPrint(
              'LoginService: Email pertenece a admin auth-only. Creando modelo temporal.');

          final tempModel = UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ??
                firebaseUser.email?.split('@')[0] ??
                'Administrador',
            role: 'admin',
            username:
                normalizeUsername((firebaseUser.email ?? '').split('@')[0]),
            hasPassword: true,
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );

          _userRepository.createUserProfile(tempModel).then((_) {
            debugPrint(
                'LoginService: Perfil admin creado en Firestore en background');
          }).catchError((e) {
            debugPrint(
                'LoginService: Error creando perfil admin en background: $e');
          });

          userModel = tempModel;
        } else {
          debugPrint(
              'LoginService: Usuario sin perfil en Firestore. Creando perfil por defecto...');

          userModel = UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ??
                firebaseUser.email?.split('@')[0] ??
                'Usuario',
            role: 'normal',
            username:
                normalizeUsername((firebaseUser.email ?? '').split('@')[0]),
            hasPassword: true,
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );

          await _userRepository.createUserProfile(userModel);
        }
      } else {
        await _userRepository.updateLastLogin(firebaseUser.uid);
      }

      debugPrint(
          'LoginService: Login exitoso: ${userModel.name} (${userModel.role})');
      return userModel;
    } catch (e) {
      debugPrint('LoginService: Error al iniciar sesión: $e');
      rethrow;
    }
  }

  /// Inicia sesión resolviendo primero el email real a partir del nombre.
  Future<UserModel?> signInWithNameAndPassword({
    required String name,
    required String password,
  }) async {
    try {
      final trimmedName = name.trim();

      debugPrint(
          'LoginService: Buscando perfil por nombre/username: $trimmedName');
      UserModel? userProfileByName;
      try {
        userProfileByName = await _userRepository.findUserByName(trimmedName);
      } catch (err) {
        debugPrint(
            'LoginService: Error leyendo Firestore al buscar usuario: $err');
        rethrow;
      }

      if (userProfileByName == null) {
        debugPrint(
            'LoginService: No se encontró perfil para el nombre: $trimmedName');
        return null;
      }

      if (userProfileByName.email.trim().isEmpty) {
        debugPrint(
            'LoginService: Perfil encontrado pero email vacío para: $trimmedName');
        return null;
      }

      final String realEmail = userProfileByName.email;
      debugPrint(
          'LoginService: Email resuelto desde Firestore: $realEmail. Intentando login...');

      final User? firebaseUser = await _authRepository.signInWithEmailAndPassword(
        email: realEmail,
        password: password,
      );

      if (firebaseUser == null) {
        return null;
      }

      final UserModel? userModel =
          await _userRepository.getUserProfile(firebaseUser.uid);

      if (userModel == null) {
        debugPrint('LoginService: Usuario sin perfil en Firestore');
        await _authRepository.signOut();
        return null;
      }

      await _userRepository.updateLastLogin(firebaseUser.uid);

      debugPrint(
          'LoginService: Login exitoso: ${userModel.name} (${userModel.role})');
      return userModel;
    } catch (e) {
      debugPrint('LoginService: Error en login con nombre: $e');
      rethrow;
    }
  }

  /// Retorna el perfil actual si hay usuario autenticado.
  Future<UserModel?> getCurrentUserProfile(User? currentUser) async {
    try {
      if (currentUser == null) {
        debugPrint('LoginService: No hay usuario autenticado');
        return null;
      }

      return await _userRepository.getUserProfile(currentUser.uid);
    } catch (e) {
      debugPrint('LoginService: Error al obtener perfil: $e');
      return null;
    }
  }

  /// Stream del perfil del usuario autenticado.
  Stream<UserModel?> userProfileStream(User? currentUser) {
    if (currentUser == null) {
      return Stream<UserModel?>.value(null);
    }

    return _userRepository.getUserProfileStream(currentUser.uid);
  }

  /// Determina si el usuario autenticado actual es administrador.
  Future<bool> isCurrentUserAdmin(User? currentUser) async {
    final userModel = await getCurrentUserProfile(currentUser);
    return userModel?.isAdmin ?? false;
  }
}
