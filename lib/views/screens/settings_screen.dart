import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../repositories/account_repository.dart';
import '../../view_models/settings_view_model.dart';
import '../../core/app_colors.dart';
import '../widgets/nav_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = SettingsViewModel(AccountRepository());
    viewModel.loadAssociationName();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<SettingsViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: const Color(0xfff5f5f5),
          appBar: AppBar(
            title: const Text(
              "Settings",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.primary,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (vm.associationName != null)
                          Text(
                            vm.associationName!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          const SizedBox(height: 22, width: 140),
                        const SizedBox(height: 4),
                        const Text(
                          "Association",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle("General Settings"),
              _settingsTile(
                title: "Profile",
                icon: Icons.person,
                onTap: () => GoRouter.of(context).push('/profile'),
              ),
              _settingsTile(
                title: "Change PIN",
                icon: Icons.lock,
                onTap: () => GoRouter.of(context).push('/change_pin'),
              ),
              const SizedBox(height: 20),
              _sectionTitle("About"),
              _settingsTile(
                title: "About App",
                icon: Icons.info,
                onTap: () => GoRouter.of(context).push('/about_app'),
              ),
              const SizedBox(height: 20),
              _settingsTile(
                title: "Logout",
                icon: Icons.logout,
                onTap: () => vm.logout(context),
                textColor: Colors.red,
                iconColor: Colors.red,
              ),
            ],
          ),
          bottomNavigationBar: const BottomNavBar(currentIndex: 2),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required String title,
    required IconData icon,
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
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
}
