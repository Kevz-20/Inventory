import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/current_user.dart';
import '../repositories/account_repository.dart';
import '../repositories/duty_shift_repository.dart';
import '../services/db_service.dart';
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

  /// Load current account's SLPA name for the settings header.
  Future<void> loadFullName() async {
    debugPrint('[VM] loadFullName called');

    if (_fullName != null) {
      debugPrint('[VM] already cached → skip');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final name = await repository.getSlpaName();
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
    // End the active duty shift before clearing session
    try {
      final accountId = CurrentUser.accountId;
      if (accountId != null) {
        final db   = await DBService.instance.database;
        final repo = DutyShiftRepository(db);
        final active = await repo.getActiveShift(accountId);
        if (active != null) await repo.endShift(active.id);
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('memberId');
    await prefs.remove('accountId');
    await prefs.remove('firstName');
    await prefs.remove('middleName');
    await prefs.remove('lastName');
    await prefs.remove('fullName');
    await prefs.remove('slpaName');
    CurrentUser.clear();
    if (!context.mounted) return;
    Navigator.pop(context);
    if (!context.mounted) return;
    GoRouter.of(context).go('/login', extra: 'fromLogout');
  }
}
