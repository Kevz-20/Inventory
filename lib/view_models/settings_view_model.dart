import 'package:dswd_slp/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../repositories/account_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final AccountRepository repository;
  SettingsViewModel(this.repository);

  String? associationName;
  bool isLoading = false;
  String? error;

  Future<void> loadAssociationName() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      associationName = await repository.getAssociationName();
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  void logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text("Logout"),
            onPressed: () async => await _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    Navigator.pop(context);
    if (!context.mounted) return;
    GoRouter.of(context).go('/login', extra: 'fromLogout');
  }
}
