import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/task_status.dart';
import '../../services/search_service.dart';

/// Widget de barra de búsqueda y filtros avanzados para las tareas asignadas.
class SimpleTaskSearchBar extends StatelessWidget {
  final TaskSearchFilters filters;
  final ValueChanged<TaskSearchFilters> onFiltersChanged;

  const SimpleTaskSearchBar({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController.fromValue(
      TextEditingValue(
        text: filters.query,
        selection: TextSelection.collapsed(offset: filters.query.length),
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _buildSearchField(controller)),
              const SizedBox(width: 12),
              _buildStatusDropdown(context),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildPriorityDropdown(context)),
              const SizedBox(width: 12),
              _buildDateRangeButton(context),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.start,
            spacing: 12,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Solo vencidas'),
                selected: filters.onlyOverdue,
                onSelected: (selected) {
                  onFiltersChanged(filters.copyWith(onlyOverdue: selected));
                },
              ),
              if (filters.dueDateRange != null)
                InputChip(
                  label: Text(_rangeLabel(filters.dueDateRange!)),
                  avatar: const Icon(Icons.date_range, size: 18),
                  onDeleted: () =>
                      onFiltersChanged(filters.copyWith(dueDateRange: null)),
                ),
              if (filters.hasActiveFilters)
                TextButton.icon(
                  onPressed: () => onFiltersChanged(const TaskSearchFilters()),
                  icon: const Icon(Icons.filter_alt_off, size: 18),
                  label: const Text('Limpiar filtros'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: (value) => onFiltersChanged(filters.copyWith(query: value)),
        decoration: InputDecoration(
          hintText: 'Buscar por título, descripción o comentarios...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF667eea)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TaskStatus?>(
          value: filters.status,
          icon: const Icon(Icons.expand_more),
          hint: const Text('Estado'),
          onChanged: (value) =>
              onFiltersChanged(filters.copyWith(status: value)),
          items: [
            const DropdownMenuItem<TaskStatus?>(
              value: null,
              child: Text('Todos'),
            ),
            ...TaskStatus.values.map(
              (status) => DropdownMenuItem<TaskStatus?>(
                value: status,
                child: Text(_statusLabel(status)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityDropdown(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TaskPriority?>(
          value: filters.priority,
          icon: const Icon(Icons.expand_more),
          hint: const Text('Prioridad'),
          onChanged: (value) =>
              onFiltersChanged(filters.copyWith(priority: value)),
          items: const [
            DropdownMenuItem<TaskPriority?>(
              value: null,
              child: Text('Todas'),
            ),
            DropdownMenuItem<TaskPriority?>(
              value: TaskPriority.high,
              child: Text('Alta'),
            ),
            DropdownMenuItem<TaskPriority?>(
              value: TaskPriority.medium,
              child: Text('Media'),
            ),
            DropdownMenuItem<TaskPriority?>(
              value: TaskPriority.low,
              child: Text('Baja'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeButton(BuildContext context) {
    final label = filters.dueDateRange != null
        ? 'Vence: ${_rangeLabel(filters.dueDateRange!)}'
        : 'Rango de fechas';

    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _pickDateRange(context),
        icon: const Icon(Icons.date_range),
        label: Text(label),
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialRange = filters.dueDateRange ??
        DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 7)),
        );

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      initialDateRange: initialRange,
      locale: const Locale('es', 'ES'),
    );

    if (range != null) {
      onFiltersChanged(filters.copyWith(dueDateRange: range));
    }
  }

  String _rangeLabel(DateTimeRange range) {
    final formatter = DateFormat('dd/MM/yy');
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pendiente';
      case TaskStatus.inProgress:
        return 'En progreso';
      case TaskStatus.pendingReview:
        return 'En revisión';
      case TaskStatus.completed:
        return 'Completada';
      case TaskStatus.confirmed:
        return 'Confirmada';
      case TaskStatus.rejected:
        return 'Rechazada';
    }
  }
}
