import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import 'auth_repository.dart';
import 'login_service.dart';
import 'registration_service.dart';
import 'session_token_service.dart';
import 'user_repository.dart';

/// Gestor de sesión que coordina AuthRepository y UserRepository.
/// Mantiene la API pública utilizada por el resto de la aplicación.
class SessionManager {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  late final LoginService _loginService;
  late final RegistrationService _registrationService;
  final SessionTokenService _tokenService;

  static const List<String> _authOnlyAdminEmails = <String>['admin@gmail.com'];

  SessionManager({
    AuthRepository? authRepository,
    UserRepository? userRepository,
    LoginService? loginService,
    RegistrationService? registrationService,
    SessionTokenService? tokenService,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _userRepository = userRepository ?? UserRepository(),
        _tokenService = tokenService ?? SessionTokenService() {
    _loginService = loginService ??
        LoginService(
          authRepository: _authRepository,
          userRepository: _userRepository,
          authOnlyAdminEmails: _authOnlyAdminEmails,
        );
    _registrationService = registrationService ??
        RegistrationService(
          authRepository: _authRepository,
          userRepository: _userRepository,
        );
  }

  /// Stream para conocer el estado de autenticación.
  Stream<User?> get authStateChanges => _authRepository.authStateChanges;

  /// Usuario actual de Firebase Auth.
  User? get currentUser => _authRepository.currentUser;

  /// Registro completo (Auth + Firestore) mediante email/contraseña.
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String role = 'normal',
  }) {
    return _registrationService.registerWithEmailAndPassword(
      email: email,
      password: password,
      name: name,
      role: role,
    );
  }

  /// Login con email/contraseña delegando en LoginService y registrando tokens.
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final userModel = await _loginService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userModel != null) {
      await _tokenService.handlePostLogin();
    }

    return userModel;
  }

  /// Registro con nombre/contraseña (genera email fake tras bambalinas).
  Future<String?> registerWithNameAndPassword({
    required String name,
    required String password,
    String role = 'normal',
  }) {
    return _registrationService.registerWithNameAndPassword(
      name: name,
      password: password,
      role: role,
    );
  }

  /// Login resolviendo el email real desde Firestore.
  Future<UserModel?> signInWithNameAndPassword({
    required String name,
    required String password,
  }) {
    return _loginService.signInWithNameAndPassword(
      name: name,
      password: password,
    );
  }

  /// Obtiene el perfil del usuario autenticado actual.
  Future<UserModel?> getCurrentUserProfile() {
    return _loginService.getCurrentUserProfile(currentUser);
  }

  /// Stream en tiempo real del perfil del usuario autenticado.
  Stream<UserModel?> get userProfileStream {
    return _loginService.userProfileStream(currentUser);
  }

  /// Cierra la sesión y limpia tokens del dispositivo.
  Future<void> signOut() async {
    await _tokenService.handlePreSignOut();
    await _authRepository.signOut();
  }

  /// Determina si el usuario actual es administrador.
  Future<bool> isCurrentUserAdmin() {
    return _loginService.isCurrentUserAdmin(currentUser);
  }

  /// Cambia la contraseña del usuario autenticado.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _authRepository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Elimina la cuenta del usuario y su perfil en Firestore.
  Future<bool> deleteAccount(String password) async {
    try {
      final User? user = currentUser;
      if (user == null) return false;

      await _userRepository.deleteUserProfile(user.uid);
      return await _authRepository.deleteAccount(password);
    } catch (_) {
      return false;
    }
  }

  /// Actualiza campos básicos del perfil en Firestore.
  Future<bool> updateUserProfile({
    required String userId,
    String? name,
    String? role,
  }) {
    return _userRepository.updateUserProfile(
      userId: userId,
      name: name,
      role: role,
    );
  }

  /// Verifica si el nombre indicado ya está en uso.
  Future<bool> isNameTaken(String name) {
    return _registrationService.isNameTaken(name);
  }

  /// Envía correo de restablecimiento de contraseña.
  Future<void> sendPasswordResetEmail(String email) {
    return _authRepository.sendPasswordResetEmail(email);
  }

  /// Crea usuarios desde el panel de administración.
  Future<String?> createUserAsAdmin({
    required String email,
    required String password,
    required String name,
    required String role,
  }) {
    return _registrationService.createUserAsAdmin(
      email: email,
      password: password,
      name: name,
      role: role,
    );
  }

  /// Elimina perfiles de usuario desde el panel de administración.
  Future<bool> deleteUserAsAdmin({
    required String userId,
  }) async {
    try {
      await _userRepository.deleteUserProfile(userId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
