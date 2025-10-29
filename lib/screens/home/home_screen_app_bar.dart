import 'package:flutter/material.dart';
import '../../models/user_model.dart';

/// AppBar personalizado para la pantalla principal
/// Muestra información del usuario y botones de navegación
class HomeScreenAppBar extends StatelessWidget {
  final UserModel user;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onLogout;

  const HomeScreenAppBar({
    super.key,
    required this.user,
    required this.scaffoldKey,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildUserAvatar(),
          const SizedBox(width: 16),
          Expanded(child: _buildUserInfo()),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  /// Avatar del usuario con gradiente según rol
  Widget _buildUserAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: user.isAdmin
            ? const LinearGradient(
                colors: [Color(0xFFff416c), Color(0xFFff4b2b)],
              )
            : const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: user.isAdmin
                ? const Color(0xFFff416c).withOpacity(0.4)
                : const Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        user.isAdmin ? Icons.admin_panel_settings : Icons.person,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  /// Información del usuario (nombre y rol)
  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bienvenido de vuelta',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.name,
          style: const TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        _buildRoleBadge(),
      ],
    );
  }

  /// Badge del rol del usuario
  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: user.isAdmin
            ? const LinearGradient(
                colors: [Color(0xFFff416c), Color(0xFFff4b2b)],
              )
            : const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        user.isAdmin ? 'Administrador' : 'Usuario',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Botones de acción (menú y logout)
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            icon: Icon(Icons.menu, color: Colors.grey.shade700),
            onPressed: () {
              scaffoldKey.currentState?.openDrawer();
            },
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            icon: Icon(Icons.logout, color: Colors.grey.shade700),
            onPressed: onLogout,
          ),
        ),
      ],
    );
  }
}
