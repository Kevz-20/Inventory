import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../providers/app_session_provider.dart';
import '../../providers/profile_view_model_provider.dart';
import '../../services/db_service.dart';
import '../../view_models/settings_view_model.dart';
import '../../repositories/account_repository.dart';
import '../widgets/nav_bar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const double _screenPadding = 16;
  static const double _sectionSpacing = 24;
  static const double _itemSpacing = 8;

  late final SettingsViewModel settingsVM;

  @override
  void initState() {
    super.initState();
    settingsVM = SettingsViewModel(AccountRepository());
    settingsVM.loadFullName(); // Load full name of current account
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = ref.watch(profileViewModelProvider);
    final account = profileVM.account;
    final appSession = ref.watch(currentAppSessionProvider);
    final canOpenAdminMonitoring = appSession.maybeWhen(
      data: (session) {
        final roles = session.authenticatedSession?.memberships
                .where((membership) => membership.status == 'active')
                .map((membership) => membership.roleCode)
                .toSet() ??
            <String>{};
        return roles.contains('pdo_consultant') ||
            roles.contains('system_admin') ||
            roles.contains('slpa_admin');
      },
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(_screenPadding),
        children: [
          /// PROFILE HEADER
          AnimatedBuilder(
            animation: settingsVM,
            builder: (context, child) {
              // Show loading indicator if fullName not yet loaded
              final isLoading = settingsVM.isLoading;
              final nameToShow = isLoading
                  ? 'Loading...'
                  : settingsVM.fullName ?? '—'; // <-- updated

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: account?.profileImage != null
                          ? FileImage(File(account!.profileImage!))
                          : null,
                      backgroundColor: AppColors.primary,
                      child: account?.profileImage == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 32,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nameToShow,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Account",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: _sectionSpacing),
          _sectionTitle("General Settings"),
          const SizedBox(height: _itemSpacing),

          _settingsTile(
            title: "Profile",
            icon: Icons.person,
            onTap: () => GoRouter.of(context).push('/profile'),
          ),
          const SizedBox(height: _itemSpacing),
          _settingsTile(
            title: "Change PIN",
            icon: Icons.lock,
            onTap: () => GoRouter.of(context).push('/change_pin'),
          ),

          const SizedBox(height: _sectionSpacing),
          _sectionTitle("About"),
          const SizedBox(height: _itemSpacing),

          _settingsTile(
            title: "About App",
            icon: Icons.info,
            onTap: () => GoRouter.of(context).push('/about_app'),
          ),

          const SizedBox(height: _sectionSpacing),
          _sectionTitle("Sync"),
          const SizedBox(height: _itemSpacing),

          _settingsTile(
            title: "Sync History",
            icon: Icons.sync_alt_rounded,
            onTap: () => GoRouter.of(context).push('/sync_history'),
          ),
          const SizedBox(height: _itemSpacing),
          _settingsTile(
            title: "Sync Diagnostics",
            icon: Icons.fact_check_outlined,
            onTap: () => GoRouter.of(context).push('/sync_diagnostics'),
          ),
          const SizedBox(height: _itemSpacing),
          _settingsTile(
            title: "Audit Log",
            icon: Icons.history_edu_outlined,
            onTap: () => GoRouter.of(context).push('/audit_logs'),
          ),
          if (canOpenAdminMonitoring) ...[
            const SizedBox(height: _itemSpacing),
            _settingsTile(
              title: "Admin Monitoring",
              icon: Icons.admin_panel_settings_outlined,
              onTap: () => GoRouter.of(context).push('/admin_monitoring'),
            ),
          ],

          const SizedBox(height: _sectionSpacing),
          _sectionTitle("Data"),
          const SizedBox(height: _itemSpacing),

          _settingsTile(
            title: "Clear Data (for testing)",
            icon: Icons.delete_forever,
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Clear data"),
                  content: const Text("This will clear ALL data.\n\nContinue?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Reset"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await DBService.instance.clearData();

                if (!mounted) return;

                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Clear data complete"),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),

          const SizedBox(height: _itemSpacing),
          _settingsTile(
            title: "Logout",
            icon: Icons.logout,
            onTap: () => settingsVM.logout(context),
            textColor: Colors.red,
            iconColor: Colors.red,
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Colors.grey,
    ),
  );

  Widget _settingsTile({
    required String title,
    required IconData icon,
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? const Color.fromARGB(255, 1, 37, 10),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    ),
  );
}
