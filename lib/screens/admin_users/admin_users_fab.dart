import 'package:flutter/material.dart';
import 'create_user_dialog.dart';

/// Floating Action Button para crear nuevo usuario
class AdminUsersFab extends StatelessWidget {
  final VoidCallback onUserCreated;

  const AdminUsersFab({
    super.key,
    required this.onUserCreated,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => CreateUserDialog(
            onUserCreated: onUserCreated,
          ),
        );
      },
      backgroundColor: Colors.red.shade600,
      elevation: 4,
      icon: const Icon(Icons.person_add, color: Colors.white, size: 18),
      label: const Text(
        "Nuevo Usuario",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
