import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';

/// Diálogo para eliminar usuario con confirmación de contraseña
class DeleteUserDialog extends StatefulWidget {
  final UserModel user;
  final VoidCallback onUserDeleted;

  const DeleteUserDialog({
    super.key,
    required this.user,
    required this.onUserDeleted,
  });

  @override
  State<DeleteUserDialog> createState() => _DeleteUserDialogState();
}

class _DeleteUserDialogState extends State<DeleteUserDialog> {
  final passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isPasswordError = false;
  static const String adminPassword = "4411";

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    // Verificar contraseña
    if (passwordController.text != adminPassword) {
      setState(() {
        isPasswordError = true;
      });
      return;
    }

    print('🗑️ Intentando eliminar usuario: ${widget.user.uid}');

    try {
      final success = await AdminService.deleteUser(widget.user.uid);

      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        print('✅ Usuario eliminado exitosamente');
        _showSuccessDialog();
      } else {
        print('❌ Error al eliminar usuario');
        _showErrorMessage();
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      print('💥 Excepción al eliminar usuario: $e');
      _showExceptionMessage(e.toString());
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Usuario Eliminado',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usuario "${widget.user.name}" eliminado de la base de datos.',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.shade300,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Colors.orange.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Información Importante',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La cuenta de autenticación de Firebase puede seguir existiendo. Para eliminar completamente la cuenta de autenticación, es necesario usar herramientas administrativas adicionales.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onUserDeleted();
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Error al eliminar usuario'),
            const SizedBox(height: 4),
            const Text(
              'Verifica los permisos o revisa la consola',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showExceptionMessage(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade600.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.warning,
              color: Colors.red.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Confirmar Eliminación',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¿Estás seguro de que quieres eliminar este usuario?'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nombre: ${widget.user.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Contraseña: ${widget.user.hasPassword ? 'Sí' : 'No'}'),
                Text(
                    'Rol: ${widget.user.isAdmin ? 'Administrador' : 'Usuario'}'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Campo de contraseña de administrador
          TextField(
            controller: passwordController,
            obscureText: !isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Contraseña de Administrador',
              errorText: isPasswordError ? 'Contraseña incorrecta' : null,
              prefixIcon: const Icon(Icons.security, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    isPasswordVisible = !isPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade600),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Text(
            'Esta acción no se puede deshacer.',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
          ),
          onPressed: _handleDelete,
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}
