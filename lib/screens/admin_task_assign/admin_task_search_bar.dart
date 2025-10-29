import 'package:flutter/material.dart';

/// Widget de búsqueda y filtrado de tareas
class AdminTaskSearchBar extends StatelessWidget {
  final String searchQuery;
  final String statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;

  const AdminTaskSearchBar({
    super.key,
    required this.searchQuery,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar tareas...',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF718096)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              initialValue: statusFilter,
              icon: const Icon(Icons.filter_list, color: Color(0xFF718096)),
              tooltip: 'Filtrar por estado',
              onSelected: onFilterChanged,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      Icon(Icons.all_inclusive, size: 18),
                      SizedBox(width: 8),
                      Text('Todas'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'pending',
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 18, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Pendientes'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'completed',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Completadas'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'overdue',
                  child: Row(
                    children: [
                      Icon(Icons.warning, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Vencidas'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
