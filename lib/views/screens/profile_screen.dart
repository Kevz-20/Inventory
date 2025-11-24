import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../../view_models/profile_view_model.dart';
import '../widgets/nav_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('[ProfileScreen] build() called');

    final vm = ref.watch(profileViewModelProvider);
    debugPrint(
      '[ProfileScreen] Provider watched: isLoading=${vm.isLoading}, account=${vm.account}',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${vm.error}'),
                  ElevatedButton(
                    onPressed: () async {
                      debugPrint('[ProfileScreen] Refresh pressed');
                      await ref.read(profileViewModelProvider).refreshAccount();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : vm.account == null
          ? const Center(child: Text('No account found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    vm.account!.associationName ?? 'No Name Provided',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),

                  _sectionTitle('Account Information'),
                  _infoCard([
                    _infoRow(
                      Icons.numbers,
                      'Mobile Number',
                      vm.account!.mobileNumber,
                    ),
                    if (vm.account!.associationName != null)
                      _infoRow(
                        Icons.business,
                        'Association',
                        vm.account!.associationName!,
                      ),
                    if (vm.account!.securityQuestionId != null)
                      _infoRow(
                        Icons.security,
                        'Security Question ID',
                        vm.account!.securityQuestionId.toString(),
                      ),
                    if (vm.account!.securityAnswer != null)
                      _infoRow(
                        Icons.question_answer,
                        'Security Answer',
                        vm.account!.securityAnswer!,
                      ),
                  ]),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      debugPrint('[ProfileScreen] Edit Profile pressed');
                    },
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
    );
  }
}

Widget _sectionTitle(String title) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );
}

Widget _infoCard(List<Widget> children) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 51),
          blurRadius: 2,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(children: children),
  );
}

Widget _infoRow(IconData icon, String label, String value) {
  return Column(
    children: [
      Row(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      const Divider(height: 20),
    ],
  );
}
