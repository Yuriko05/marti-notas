import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Barra de búsqueda y filtros para tareas del usuario
class UserTaskSearchBar extends StatelessWidget {
  final String searchQuery;
  final String priorityFilter;
  final Function(String) onSearchChanged;
  final Function(String?) onPriorityChanged;

  const UserTaskSearchBar({
    super.key,
    required this.searchQuery,
    required this.priorityFilter,
    required this.onSearchChanged,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Buscador
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppBorderRadius.mdRadius,
                boxShadow: [AppColors.shadowSm],
              ),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar tareas...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: AppSpacing.sm),
          
          // Filtro de prioridad
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppBorderRadius.mdRadius,
              boxShadow: [AppColors.shadowSm],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: priorityFilter,
                icon: const Icon(Icons.filter_list_rounded, size: 20),
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Todas')),
                  DropdownMenuItem(
                    value: 'high',
                    child: Row(
                      children: [
                        Icon(Icons.flag, color: Color(0xFFfc4a1a), size: 16),
                        SizedBox(width: 8),
                        Text('Alta'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'medium',
                    child: Row(
                      children: [
                        Icon(Icons.flag, color: Color(0xFFf7b733), size: 16),
                        SizedBox(width: 8),
                        Text('Media'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'low',
                    child: Row(
                      children: [
                        Icon(Icons.flag, color: Color(0xFF43e97b), size: 16),
                        SizedBox(width: 8),
                        Text('Baja'),
                      ],
                    ),
                  ),
                ],
                onChanged: onPriorityChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
