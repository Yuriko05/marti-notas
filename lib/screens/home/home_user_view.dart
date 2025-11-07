import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'user_dashboard.dart';

/// Vista principal para usuarios normales (no administradores)
class HomeUserView extends StatelessWidget {
  final UserModel user;

  const HomeUserView({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return UserDashboard(user: user);
  }
}
