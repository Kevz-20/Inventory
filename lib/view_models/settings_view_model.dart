import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../repositories/account_repository.dart';
import '../core/app_colors.dart';

class SettingsViewModel extends ChangeNotifier {
  final AccountRepository repository;
  SettingsViewModel(this.repository);

  String? _associationName;
  final bool _isLoading = false;
  String? _error;

  String? get associationName => _associationName;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAssociationName() async {
    debugPrint('[VM] loadAssociationName called');

    if (_associationName != null) {
      debugPrint('[VM] already cached → skip');
      return;
    }

    try {
      final name = await repository.getAssociationName();
      debugPrint('[VM] fetched name=$name');

      if (name != null) {
        _associationName = name;
        debugPrint('[VM] notify once');
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
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

  Future<void> _handleLogout(BuildContext context) async {
    Navigator.pop(context);
    if (!context.mounted) return;
    GoRouter.of(context).go('/login', extra: 'fromLogout');
  }
}
