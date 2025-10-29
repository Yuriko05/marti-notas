import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../tasks_screen.dart';
import '../admin_users_screen.dart';
import '../simple_task_assign_screen.dart';
import '../admin_tasks_by_user_screen.dart';

/// Vista principal para administradores
class HomeAdminView extends StatelessWidget {
  final UserModel user;
  final VoidCallback onShowStats;

  const HomeAdminView({
    super.key,
    required this.user,
    required this.onShowStats,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildPremiumAdminHeader(),
          const SizedBox(height: 20),
          _buildAdminMenu(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Header premium para administrador
  Widget _buildPremiumAdminHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFff416c),
            Color(0xFFff4b2b),
            Color(0xFFfc466b),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFff416c).withOpacity(0.5),
            blurRadius: 25,
            offset: const Offset(0, 12),
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            '✨ Bienvenido CPC  La contabilidad es tu visión estratégica',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'La contabilidad no es solo números, es visión, control y la excelencia de un contador colegiado',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Menú de opciones para administrador
  Widget _buildAdminMenu(BuildContext context) {
    return Column(
      children: [
        _buildMenuTile(
          context: context,
          icon: Icons.people,
          title: 'Gestión de Usuarios',
          subtitle: 'Administrar cuentas',
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminUsersScreen(currentUser: user),
            ),
          ),
        ),
        _buildMenuTile(
          context: context,
          icon: Icons.assignment,
          title: 'Asignación de Tareas',
          subtitle: 'Delegar al equipo',
          color: Colors.red,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SimpleTaskAssignScreen(currentUser: user),
            ),
          ),
        ),
        _buildMenuTile(
          context: context,
          icon: Icons.group_work,
          title: 'Tareas por Usuario',
          subtitle: 'Ver progreso del equipo',
          color: Colors.teal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminTasksByUserScreen(),
            ),
          ),
        ),
        _buildMenuTile(
          context: context,
          icon: Icons.task_alt,
          title: 'Mis Tareas Personales',
          subtitle: 'Gestión privada',
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TasksScreen(user: user),
            ),
          ),
        ),
        _buildMenuTile(
          context: context,
          icon: Icons.analytics,
          title: 'Estadísticas Avanzadas',
          subtitle: 'Métricas del sistema',
          color: Colors.purple,
          onTap: onShowStats,
        ),
      ],
    );
  }

  /// Tile individual del menú
  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey.shade400,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
