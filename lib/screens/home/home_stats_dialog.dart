import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

/// Diálogo de estadísticas del sistema para administradores
class HomeStatsDialog {
  /// Mostrar diálogo de estadísticas
  static Future<void> show(BuildContext context) async {
    // Mostrar loading premium
    _showLoadingDialog(context);

    final stats = await AdminService.getSystemStats();

    if (!context.mounted) return;
    Navigator.pop(context); // Cerrar loading

    if (stats == null) {
      _showErrorSnackBar(context);
      return;
    }

    // Mostrar estadísticas compactas
    _showStatsDialog(context, stats);
  }

  /// Diálogo de carga
  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Analizando estadísticas...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Recopilando métricas del sistema',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// SnackBar de error
  static void _showErrorSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Error al cargar estadísticas',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFff416c),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Diálogo con las estadísticas
  static void _showStatsDialog(
      BuildContext context, Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 500),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildStatsContent(stats),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header del diálogo
  static Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade600,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Estadísticas del Sistema',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Contenido del diálogo con estadísticas
  static Widget _buildStatsContent(Map<String, dynamic> stats) {
    return Column(
      children: [
        _buildCompactStatItem(
            '👥 Usuarios', stats['totalUsers'] ?? 0, Colors.blue),
        _buildCompactStatItem(
            '🔴 Administradores', stats['adminUsers'] ?? 0, Colors.red),
        _buildCompactStatItem(
            '🔵 Usuarios Activos', stats['normalUsers'] ?? 0, Colors.green),
        const SizedBox(height: 12),
        Divider(color: Colors.grey.shade300, height: 1),
        const SizedBox(height: 12),
        _buildCompactStatItem(
            '📋 Tareas Totales', stats['totalTasks'] ?? 0, Colors.purple),
        _buildCompactStatItem(
            '🟡 Pendientes', stats['pendingTasks'] ?? 0, Colors.orange),
        _buildCompactStatItem(
            '✅ Completadas', stats['completedTasks'] ?? 0, Colors.green),
        const SizedBox(height: 12),
        Divider(color: Colors.grey.shade300, height: 1),
        const SizedBox(height: 12),
        _buildCompactStatItem(
            '📝 Notas', stats['totalNotes'] ?? 0, Colors.cyan),
      ],
    );
  }

  /// Item individual de estadística
  static Widget _buildCompactStatItem(String label, int value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
