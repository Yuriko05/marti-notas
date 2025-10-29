import 'package:flutter/material.dart';
import '../../services/task_cleanup_service.dart';
import '../../utils/ui_helper.dart';

/// Widget que muestra los botones de acción flotantes
class AdminTaskFab extends StatelessWidget {
  final VoidCallback onAddTask;
  final VoidCallback onCleanupComplete;

  const AdminTaskFab({
    super.key,
    required this.onAddTask,
    required this.onCleanupComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Botón de limpieza manual
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFee7724), Color(0xFFd8363a)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFee7724).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            heroTag: "cleanup_button",
            onPressed: () => _performManualCleanup(context),
            backgroundColor: Colors.transparent,
            elevation: 0,
            tooltip: 'Limpieza manual de tareas completadas',
            child: const Icon(Icons.cleaning_services,
                color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(height: 12),
        // Botón principal de nueva tarea
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            heroTag: "add_task_button",
            onPressed: onAddTask,
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.add_task, color: Colors.white),
            label: const Text(
              'Nueva Tarea',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Ejecuta limpieza manual y muestra estadísticas
  Future<void> _performManualCleanup(BuildContext context) async {
    try {
      // Mostrar dialog de confirmación con estadísticas
      final stats = await TaskCleanupService.getCleanupStatistics();
      final totalTasks = stats['totalTasks'] ?? 0;

      if (!context.mounted) return;

      if (totalTasks == 0) {
        UIHelper.showInfoSnackBar(
          context,
          'No hay tareas completadas que requieran limpieza',
        );
        return;
      }

      final confirm = await showDialog<bool>(
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
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.cleaning_services,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Limpieza Manual'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Deseas ejecutar limpieza manual de tareas completadas?',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📋 Tareas a eliminar: $totalTasks'),
                    const Text('⏰ Completadas hace más de 24 horas'),
                    const SizedBox(height: 4),
                    const Text(
                      'Esta acción no se puede deshacer.',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Limpiar'),
            ),
          ],
        ),
      );

      if (confirm == true && context.mounted) {
        // Mostrar loading
        UIHelper.showLoadingDialog(context, message: 'Limpiando tareas...');

        // Ejecutar limpieza
        await TaskCleanupService.adminCleanupAllCompletedTasks();

        if (!context.mounted) return;

        // Cerrar loading
        Navigator.of(context).pop();

        UIHelper.showSuccessSnackBar(
          context,
          'Limpieza completada: $totalTasks tareas eliminadas',
        );

        // Recargar datos
        onCleanupComplete();
      }
    } catch (e) {
      if (!context.mounted) return;

      // Cerrar loading si está abierto
      Navigator.of(context).pop();

      UIHelper.showErrorSnackBar(
        context,
        'Error durante la limpieza: ${e.toString()}',
      );
    }
  }
}
