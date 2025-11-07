import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'admin_dashboard.dart';

/// Vista principal para administradores
class HomeAdminView extends StatelessWidget {
  final UserModel user;

  const HomeAdminView({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return AdminDashboard(admin: user);
  }
}
