import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../providers/profile_view_model_provider.dart';
import '../../repositories/account_repository.dart';
import '../../services/db_service.dart';
import '../../view_models/settings_view_model.dart';
import '../widgets/dashboard_background.dart';
import '../widgets/primary_footer_nav.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const Color _pageBg = Color(0xFFF5F7FF);
  static const Color _cardBg = Colors.white;
  static const Color _cardBorder = Color(0xFFDDE5F8);
  static const Color _textPrimary = Color(0xFF213A6B);
  static const Color _textSecondary = Color(0xFF60739B);
  static const Color _accentBlue = Color(0xFF2F6BFF);

  late final SettingsViewModel settingsVM;

  @override
  void initState() {
    super.initState();
    settingsVM = SettingsViewModel(AccountRepository());
    settingsVM.loadFullName();
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = ref.watch(profileViewModelProvider);
    final account = profileVM.account;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: _pageBg,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: _pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Image.asset(
            'lib/assets/arrowleft.png',
            width: 22,
            height: 22,
            fit: BoxFit.contain,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Stack(
        children: [
          const DashboardBackground(),
          SafeArea(
            top: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 18 + bottomInset),
              children: [
                AnimatedBuilder(
                  animation: settingsVM,
                  builder: (context, child) {
                    final isLoading = settingsVM.isLoading;
                    final nameToShow =
                        isLoading ? 'Loading...' : settingsVM.fullName ?? '-';

                    return _profileHero(
                      name: nameToShow,
                      profileImagePath: account?.profileImage,
                    );
                  },
                ),
                const SizedBox(height: 20),
                _sectionHeader('General Settings'),
                const SizedBox(height: 10),
                _settingsTile(
                  title: 'Profile',
                  subtitle: 'Manage account details and photo',
                  icon: Icons.person_rounded,
                  onTap: () => context.push('/profile'),
                ),
                const SizedBox(height: 10),
                _settingsTile(
                  title: 'Add Member',
                  subtitle: 'Register another SLPA member',
                  icon: Icons.group_add_rounded,
                  onTap: () => context.push('/add_member'),
                ),
                const SizedBox(height: 10),
                _settingsTile(
                  title: 'Activity Log',
                  subtitle: 'Review recorded system actions',
                  icon: Icons.fact_check_outlined,
                  onTap: () => context.push('/activity_log'),
                ),
                const SizedBox(height: 10),
                _settingsTile(
                  title: 'Sync Center',
                  subtitle: 'Check sync state and pending records',
                  icon: Icons.sync_alt_rounded,
                  onTap: () => context.push('/sync_center'),
                ),
                const SizedBox(height: 10),
                _settingsTile(
                  title: 'Change PIN',
                  subtitle: 'Update your security PIN',
                  icon: Icons.lock_rounded,
                  onTap: () => context.push('/change_pin'),
                ),
                const SizedBox(height: 22),
                _sectionHeader('About'),
                const SizedBox(height: 10),
                _settingsTile(
                  title: 'About App',
                  subtitle: 'View application information',
                  icon: Icons.info_rounded,
                  onTap: () => context.push('/about_app'),
                ),
                const SizedBox(height: 22),
                _sectionHeader('Data'),
                const SizedBox(height: 10),
                _settingsTile(
                  title: 'Clear Data (for testing)',
                  subtitle: 'Erase all local data from this device',
                  icon: Icons.delete_forever_rounded,
                  iconColor: const Color(0xFFE04A4A),
                  accentColor: const Color(0xFFFFF1F1),
                  textColor: const Color(0xFFE04A4A),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Clear data'),
                        content: const Text(
                          'This will clear ALL data.\n\nContinue?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await DBService.instance.clearData();

                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text('Clear data complete'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
                _settingsTile(
                  title: 'Logout',
                  subtitle: 'Sign out of the current account',
                  icon: Icons.logout_rounded,
                  iconColor: const Color(0xFFE04A4A),
                  accentColor: const Color(0xFFFFF1F1),
                  textColor: const Color(0xFFE04A4A),
                  onTap: () => settingsVM.logout(context),
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const PrimaryFooterNav(
        selectedTab: PrimaryFooterTab.settings,
      ),
    );
  }

  Widget _profileHero({
    required String name,
    required String? profileImagePath,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF173D86),
            Color(0xFF1D79D8),
            Color(0xFF28C4D5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4A9A).withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            top: -18,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: profileImagePath != null
                      ? Image.file(
                          File(profileImagePath),
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'SLPA Account',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: _textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
    Color? accentColor,
  }) {
    final resolvedTextColor = textColor ?? _textPrimary;
    final resolvedIconColor = iconColor ?? _accentBlue;
    final resolvedAccentColor = accentColor ?? const Color(0xFFEAF2FF);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8EA1D1).withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: resolvedAccentColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: resolvedIconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: resolvedTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: _textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
