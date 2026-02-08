import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../repositories/account_repository.dart';
import '../core/app_colors.dart';

class SettingsViewModel extends ChangeNotifier {
  final AccountRepository repository;

  SettingsViewModel(this.repository);

  String? _fullName;
  bool _isLoading = false;
  String? _error;

  String? get fullName => _fullName;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load current account's full name (first + middle + last)
  Future<void> loadFullName() async {
    debugPrint('[VM] loadFullName called');

    if (_fullName != null) {
      debugPrint('[VM] already cached → skip');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Use getFullName from AccountRepository
      final name = await repository.getFullName();
      debugPrint('[VM] fetched fullName=$name');

      _fullName = name;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('[VM] error fetching fullName: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout dialog
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
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async => _handleLogout(context),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  /// Handle actual logout
  Future<void> _handleLogout(BuildContext context) async {
    Navigator.pop(context);
    if (!context.mounted) return;
    GoRouter.of(context).go('/login', extra: 'fromLogout');
  }
}
