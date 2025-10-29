import 'package:flutter/material.dart';

/// Barra de pestañas simple para la pantalla de tareas.
class TaskTabBar extends StatelessWidget {
  final TabController tabController;
  final String userId;

  const TaskTabBar(
      {super.key, required this.tabController, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: TabBar(
        controller: tabController,
        labelColor: Colors.green.shade700,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.green.shade700,
        tabs: const [
          Tab(text: 'Pendientes'),
          Tab(text: 'En Progreso'),
          Tab(text: 'Completadas'),
        ],
      ),
    );
  }
}
