import 'package:flutter/material.dart';

/// Widget de barra de búsqueda y filtros para usuarios
class AdminUsersSearchBar extends StatelessWidget {
  final String searchQuery;
  final String filterRole;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onFilterChanged;

  const AdminUsersSearchBar({
    super.key,
    required this.searchQuery,
    required this.filterRole,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: "Buscar por nombre...",
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon:
                    Icon(Icons.search, color: Colors.red.shade600, size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.red.shade600),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: filterRole,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.red.shade600),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Todos')),
                DropdownMenuItem(value: 'admin', child: Text('Admins')),
                DropdownMenuItem(value: 'normal', child: Text('Normal')),
              ],
              onChanged: onFilterChanged,
            ),
          ),
        ],
      ),
    );
  }
}
