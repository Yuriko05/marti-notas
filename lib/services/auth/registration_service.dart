import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'auth_repository.dart';
import 'user_repository.dart';
import 'username_formatter.dart';

/// Contiene la lógica de registro de usuarios y verificación de nombres.
class RegistrationService {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  RegistrationService({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository;

  /// Registro completo (Auth + Firestore) usando email y contraseña.
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String role = 'normal',
  }) async {
    try {
      final User? firebaseUser =
          await _authRepository.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (firebaseUser == null) {
        return null;
      }

      final UserModel userModel = UserModel(
        uid: firebaseUser.uid,
        email: email,
        name: name,
        role: role,
        username: normalizeUsername(email.split('@')[0]),
        hasPassword: true,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _userRepository.createUserProfile(userModel);

      debugPrint(
          'RegistrationService: Usuario registrado correctamente: ${userModel.uid}');
      return userModel;
    } catch (e) {
      debugPrint('RegistrationService: Error al registrar usuario: $e');
      rethrow;
    }
  }

  /// Registro simplificado generando un email fake basado en el nombre.
  Future<String?> registerWithNameAndPassword({
    required String name,
    required String password,
    String role = 'normal',
  }) async {
    final User? currentAdminUser = _authRepository.currentUser;
    String? adminEmail;

    try {
      final existingUser = await _userRepository.findUserByName(name);
      if (existingUser != null) {
        debugPrint(
            'RegistrationService: Ya existe un usuario con el nombre: $name');
        return null;
      }

      if (currentAdminUser != null) {
        adminEmail = currentAdminUser.email;
        debugPrint(
            'RegistrationService: Admin actual guardado: ${adminEmail ?? ''}');
      }

      final String fakeEmail = _authRepository.generateFakeEmail(name);
      debugPrint('RegistrationService: Correo fake generado: $fakeEmail');

      final User? firebaseUser =
          await _authRepository.registerWithEmailAndPassword(
        email: fakeEmail,
        password: password,
      );

      if (firebaseUser == null) {
        return null;
      }

      final String newUserId = firebaseUser.uid;

      final UserModel userModel = UserModel(
        uid: newUserId,
        email: fakeEmail,
        name: name,
        role: role,
        username: normalizeUsername(name),
        hasPassword: true,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _userRepository.createUserProfile(userModel);

      debugPrint(
          'RegistrationService: Usuario creado exitosamente: $name ($newUserId)');

      await _authRepository.signOut();
      debugPrint(
          'RegistrationService: ⚠️ Admin deslogueado. Debe volver a iniciar sesión.');

      return newUserId;
    } catch (e) {
      debugPrint(
          'RegistrationService: Error al registrar usuario con nombre: $e');
      return null;
    }
  }

  /// Creación de usuario desde panel de administración.
  Future<String?> createUserAsAdmin({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final User? adminUser = _authRepository.currentUser;
      if (adminUser == null) {
        debugPrint('RegistrationService: No hay un administrador autenticado');
        return null;
      }

      final userExists = await _authRepository.checkIfUserExists(email);
      if (userExists) {
        debugPrint('RegistrationService: El email ya está en uso: $email');
        return null;
      }

      final User? newUser = await _authRepository.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (newUser == null) {
        return null;
      }

      final String newUserId = newUser.uid;

      try {
        final UserModel userModel = UserModel(
          uid: newUserId,
          email: email,
          name: name,
          role: role,
          username: normalizeUsername(name),
          hasPassword: true,
          createdAt: DateTime.now(),
        );

        await _userRepository.createUserProfile(userModel);

        await _authRepository.signOut();

        debugPrint(
            'RegistrationService: Usuario creado por admin: $email ($newUserId)');
        return newUserId;
      } catch (e) {
        await _authRepository.deleteAccount(password);
        debugPrint(
            'RegistrationService: Error al crear perfil en Firestore: $e');
        return null;
      }
    } catch (e) {
      debugPrint('RegistrationService: Error al crear usuario como admin: $e');
      return null;
    }
  }

  /// Verifica si el nombre ya está asociado a un usuario existente.
  Future<bool> isNameTaken(String name) async {
    final String fakeEmail = _authRepository.generateFakeEmail(name);
    return await _authRepository.checkIfUserExists(fakeEmail);
  }
}
