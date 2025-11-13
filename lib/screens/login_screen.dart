import 'package:flutter/material.dart';
import '../services/auth/session_manager.dart';
import '../models/user_model.dart';
import '../utils/validators.dart';
import '../utils/ui_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutBack));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final rawInput = _emailController.text.trim();
      final email = rawInput.contains('@') ? rawInput : '${rawInput}@gmail.com';
      print('Intentando iniciar sesión: $email (entrada: $rawInput)');

      // Usar login por email y contraseña (si el usuario ingresó solo nombre,
      // se concatena @gmail.com automáticamente)
      final UserModel? user = await SessionManager().signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      if (user == null) {
        if (mounted) {
          UIHelper.showErrorSnackBar(
            context,
            'Nombre de usuario o contraseña incorrectos.',
          );
        }
        return;
      }

      print('✅ Login exitoso: ${user.name} (${user.role})');
    } catch (e) {
      debugPrint('❌ Error inesperado en login: $e');

      if (mounted) {
        UIHelper.showErrorSnackBar(
          context,
          'Error de conexión. Intenta más tarde.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Validador que acepta un nombre de usuario simple (p.ej. "yuri") o un email.
  String? _validateLoginNameOrEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El usuario o correo es requerido';
    }

    final v = value.trim();

    // Si contiene @, validar como email
    if (v.contains('@')) {
      return FormValidators.validateEmail(v);
    }

      // Permitir nombres simples: letras, números, punto, guion bajo o guion
      final ok = RegExp(r'^[a-zA-Z0-9._-]{2,}$').hasMatch(v);
    if (!ok) return 'Usuario no válido';

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientCorporate,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppBorderRadius.lgRadius,
                        boxShadow: [AppColors.shadowXl],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo Premium con colores corporativos
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  gradient: AppColors.gradientCorporate,
                                  borderRadius: AppBorderRadius.xlRadius,
                                  boxShadow: [AppColors.shadowPrimary],
                                ),
                                child: const Icon(
                                  Icons.business_center_rounded,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Título Premium con colores corporativos
                              ShaderMask(
                                shaderCallback: (bounds) => AppColors
                                    .gradientCorporate
                                    .createShader(bounds),
                                child: Text(
                                  'Marti Notas',
                                  style: AppTextStyles.display1.copyWith(
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sistema Empresarial de Gestión',
                                style: AppTextStyles.subtitle1.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 48),

                              // Campo email/usuario premium. Si el user ingresa solo
                              // un nombre (ej. "yuri"), se añadirá @gmail.com al
                              // presionar Acceder.
                              _buildPremiumTextField(
                                controller: _emailController,
                                label: 'Usuario o correo',
                                icon: Icons.person_outline,
                                keyboardType: TextInputType.text,
                                validator: _validateLoginNameOrEmail,
                              ),
                              const SizedBox(height: 24),

                              // Campo contraseña premium
                              _buildPremiumTextField(
                                controller: _passwordController,
                                label: 'Contraseña Segura',
                                icon: Icons.lock_outlined,
                                isPassword: true,
                                validator: FormValidators.validatePassword,
                              ),
                              const SizedBox(height: 40),

                              // Botón de acceso con colores corporativos
                              AppButton.primary(
                                text: 'Acceder al Sistema',
                                onPressed: _isLoading ? null : _signIn,
                                isLoading: _isLoading,
                                icon: Icons.login_rounded,
                                isFullWidth: true,
                              ),
                              const SizedBox(height: 32),

                              // Footer con info corporativa
                              Text(
                                '© 2025 Marti Notas - Sistema Empresarial',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword ? !_isPasswordVisible : false,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          suffixIcon: isPassword
              ? Container(
                  margin: const EdgeInsets.all(12),
                  child: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF667eea),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFff416c),
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFff416c),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2D3748),
        ),
        validator: validator,
      ),
    );
  }
}
