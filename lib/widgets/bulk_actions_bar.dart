import 'package:flutter/material.dart';

/// Barra de acciones masivas para tareas seleccionadas
/// Aparece en la parte inferior cuando hay tareas seleccionadas
class BulkActionsBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClearSelection;
  final VoidCallback onReassign;
  final VoidCallback onChangePriority;
  final VoidCallback onDelete;
  final VoidCallback? onMarkAsRead;

  const BulkActionsBar({
    super.key,
    required this.selectedCount,
    required this.onClearSelection,
    required this.onReassign,
    required this.onChangePriority,
    required this.onDelete,
    this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Contador de seleccionadas
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '$selectedCount seleccionada${selectedCount != 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Botón limpiar selección
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Limpiar selección',
                onPressed: onClearSelection,
              ),
              const SizedBox(width: 12),
              // Acciones
              if (onMarkAsRead != null) ...[
                _buildActionButton(
                  icon: Icons.visibility,
                  label: 'Leído',
                  onPressed: onMarkAsRead!,
                ),
                const SizedBox(width: 8),
              ],
              _buildActionButton(
                icon: Icons.person_add,
                label: 'Reasignar',
                onPressed: onReassign,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.flag,
                label: 'Prioridad',
                onPressed: onChangePriority,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.delete,
                label: 'Eliminar',
                onPressed: onDelete,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return Tooltip(
      message: label,
      child: TextButton.icon(
        icon: Icon(
          icon,
          color: isDestructive ? const Color(0xFFfc4a1a) : Colors.white,
          size: 18,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: isDestructive ? const Color(0xFFfc4a1a) : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: isDestructive ? 0.95 : 0.2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
