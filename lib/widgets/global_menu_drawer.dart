import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../screens/tasks_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/admin_users_screen.dart';
import '../screens/simple_task_assign_screen.dart';
import '../screens/admin_tasks_by_user_screen.dart';

class GlobalMenuDrawer extends StatelessWidget {
  final UserModel user;

  const GlobalMenuDrawer({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _buildMenuItems(context),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                Navigator.pop(context);
                await Future.delayed(const Duration(milliseconds: 150));
                // sign out
                // We avoid importing firebase here to keep drawer simple
                // HomeScreen already handles logout via button
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: user.isAdmin
            ? const LinearGradient(
                colors: [Color(0xFFff416c), Color(0xFFff4b2b)])
            : const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              user.isAdmin ? Icons.admin_panel_settings : Icons.person,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text(user.isAdmin ? 'Administrador' : 'Usuario',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    final items = <Widget>[];

    items.add(ListTile(
      leading: const Icon(Icons.task),
      title: const Text('Mis Tareas'),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => TasksScreen(user: user)));
      },
    ));

    items.add(ListTile(
      leading: const Icon(Icons.note),
      title: const Text('Mis Notas'),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => NotesScreen(user: user)));
      },
    ));

    if (user.isAdmin) {
      items.add(const Divider());
      items.add(ListTile(
        leading: const Icon(Icons.people),
        title: const Text('Gestión de Usuarios'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AdminUsersScreen(currentUser: user)));
        },
      ));

      items.add(ListTile(
        leading: const Icon(Icons.assignment),
        title: const Text('Asignar Tarea'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SimpleTaskAssignScreen(currentUser: user)));
        },
      ));

      items.add(ListTile(
        leading: const Icon(Icons.group_work),
        title: const Text('Tareas por Usuario'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AdminTasksByUserScreen(currentUser: user)));
        },
      ));
    }

    return items;
  }
}
