import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../widgets/global_menu_drawer.dart';
import '../theme/app_theme.dart';
import 'home/home_screen_app_bar.dart';
import 'home/home_screen_fab.dart';
import 'home/home_admin_view.dart';
import 'home/home_user_view.dart';
import 'home/home_stats_dialog.dart';

/// Pantalla principal de la aplicación
/// Muestra diferentes vistas según el rol del usuario
class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Inicializar animaciones
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: GlobalMenuDrawer(user: widget.user),
      body: _buildBody(),
      floatingActionButton: HomeScreenFAB(user: widget.user),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Cuerpo principal con gradiente y contenido
  Widget _buildBody() {
    return Container(
      decoration: _buildGradientBackground(),
      child: SafeArea(
        child: Column(
          children: [
            HomeScreenAppBar(
              user: widget.user,
              scaffoldKey: _scaffoldKey,
              onLogout: _showLogoutConfirmation,
            ),
            Expanded(
              child: _buildAnimatedContent(),
            ),
          ],
        ),
      ),
    );
  }

  /// Gradiente de fondo con colores corporativos
  BoxDecoration _buildGradientBackground() {
    return const BoxDecoration(
      gradient: AppColors.gradientCorporate,
    );
  }

  /// Contenido animado según el rol del usuario
  Widget _buildAnimatedContent() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: widget.user.isAdmin
              ? HomeAdminView(
                  user: widget.user,
                  onShowStats: () => HomeStatsDialog.show(context),
                )
              : HomeUserView(user: widget.user),
        );
      },
    );
  }

  /// Mostrar diálogo de confirmación de cierre de sesión
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFf8f9fa),
                Color(0xFFe9ecef),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogoutIcon(),
              const SizedBox(height: 16),
              _buildLogoutTitle(),
              const SizedBox(height: 8),
              _buildLogoutMessage(),
              const SizedBox(height: 24),
              _buildLogoutActions(),
            ],
          ),
        ),
      ),
    );
  }

  /// Icono del diálogo de logout
  Widget _buildLogoutIcon() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFff416c), Color(0xFFff4b2b)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.logout,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  /// Título del diálogo
  Widget _buildLogoutTitle() {
    return const Text(
      'Cerrar Sesión',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3748),
      ),
    );
  }

  /// Mensaje del diálogo
  Widget _buildLogoutMessage() {
    return Text(
      '¿Estás seguro de que quieres cerrar sesión?',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade600,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Botones de acción del diálogo
  Widget _buildLogoutActions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFff416c), Color(0xFFff4b2b)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Salir',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
