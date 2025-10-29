import 'package:flutter/material.dart';
import '../../models/user_model.dart';

/// Widget de lista de usuarios con acciones
class AdminUsersList extends StatelessWidget {
  final List<UserModel> users;
  final UserModel currentUser;
  final Function(UserModel) onEdit;
  final Function(UserModel) onDelete;

  const AdminUsersList({
    super.key,
    required this.users,
    required this.currentUser,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(
        child: Text(
          "No se encontraron usuarios",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isCurrentUser = user.uid == currentUser.uid;

        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  user.isAdmin ? Colors.red.shade400 : Colors.blue.shade400,
              child: Icon(
                user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                color: Colors.white,
              ),
            ),
            title: Text(
              user.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? Colors.red.shade700 : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usuario: ${user.name}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Contraseña: ${user.password ?? 'No disponible'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: isCurrentUser
                ? const Text("Tú",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red))
                : PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit(user);
                      } else if (value == 'delete') {
                        onDelete(user);
                      }
                    },
                    iconSize: 16,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: "edit",
                        height: 30,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 12, color: Colors.blue),
                            const SizedBox(width: 4),
                            const Text("Editar",
                                style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "delete",
                        height: 30,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete, size: 12, color: Colors.red),
                            const SizedBox(width: 4),
                            const Text("Eliminar",
                                style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
