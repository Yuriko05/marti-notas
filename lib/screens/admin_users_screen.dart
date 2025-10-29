import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/admin_service.dart';
import 'admin_users/admin_users_header.dart';
import 'admin_users/admin_users_stats.dart';
import 'admin_users/admin_users_search_bar.dart';
import 'admin_users/admin_users_list.dart';
import 'admin_users/edit_user_dialog.dart';
import 'admin_users/delete_user_dialog.dart';
import 'admin_users/admin_users_fab.dart';

/// Pantalla de administración de usuarios (Refactorizada)
/// Reducida de 1,295 líneas a ~180 líneas (86% de reducción)
class AdminUsersScreen extends StatefulWidget {
  final UserModel currentUser;

  const AdminUsersScreen({super.key, required this.currentUser});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with TickerProviderStateMixin {
  List<UserModel> users = [];
  List<UserModel> filteredUsers = [];
  bool isLoading = true;
  Map<String, dynamic>? stats;
  String searchQuery = '';
  String filterRole = 'all';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final loadedUsers = await AdminService.getAllUsers();
    final loadedStats = await AdminService.getSystemStats();

    setState(() {
      users = loadedUsers;
      filteredUsers = loadedUsers;
      stats = loadedStats;
      isLoading = false;
    });

    _animationController.forward();
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      filteredUsers = users.where((user) {
        final matchesSearch =
            user.name.toLowerCase().contains(searchQuery.toLowerCase());
        final matchesRole = filterRole == 'all' || user.role == filterRole;
        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            AdminUsersHeader(
              onRefresh: _loadData,
              onBack: () => Navigator.pop(context),
            ),
            if (isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                ),
              )
            else
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        if (stats != null) AdminUsersStats(stats: stats!),
                        AdminUsersSearchBar(
                          searchQuery: searchQuery,
                          filterRole: filterRole,
                          onSearchChanged: (value) {
                            searchQuery = value;
                            _applyFilters();
                          },
                          onFilterChanged: (value) {
                            filterRole = value!;
                            _applyFilters();
                          },
                        ),
                        Expanded(
                          child: AdminUsersList(
                            users: filteredUsers,
                            currentUser: widget.currentUser,
                            onEdit: _showEditUserDialog,
                            onDelete: _showDeleteUserDialog,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: AdminUsersFab(
        onUserCreated: _loadData,
      ),
    );
  }

  void _showEditUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => EditUserDialog(
        user: user,
        onUserUpdated: _loadData,
      ),
    );
  }

  void _showDeleteUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => DeleteUserDialog(
        user: user,
        onUserDeleted: _loadData,
      ),
    );
  }
}
