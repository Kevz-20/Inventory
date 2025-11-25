import 'package:dswd_slp/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsViewModelProvider = ChangeNotifierProvider<SettingsViewModel>((
  ref,
) {
  return SettingsViewModel(ref);
});

class SettingsViewModel extends ChangeNotifier {
  final Ref ref;

  SettingsViewModel(this.ref);

  void logout(BuildContext context) {
    _showLogoutDialog(context);
  }

  void _showLogoutDialog(BuildContext context) {
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

    await _clearStoredMobileNumber();
    if (!context.mounted) return;
    GoRouter.of(context).go('/login', extra: 'fromLogout');
  }

  Future<void> _clearStoredMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mobileNumber');
  }
}
