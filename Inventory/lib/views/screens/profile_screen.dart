import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/account_model.dart';
import '../../providers/profile_view_model_provider.dart';


class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const Color _pageBg = Color(0xFFF0F4FF);
  static const Color _cardBg = Colors.white;
  static const Color _cardBorder = Color(0xFFCDD5EE);
  static const Color _textPrimary = Color(0xFF1B3A7A);
  static const Color _textSecondary = Color(0xFF5B6D96);
  static const Color _accentBlue = Color(0xFF2D5BE3);

  bool _editMode = false;
  late final TextEditingController firstNameCtrl;
  late final TextEditingController middleNameCtrl;
  late final TextEditingController lastNameCtrl;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    firstNameCtrl = TextEditingController();
    middleNameCtrl = TextEditingController();
    lastNameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    middleNameCtrl.dispose();
    lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(profileViewModelProvider);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: _pageBg,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFCDD5EE)),
        ),
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
              context.go('/settings');
            }
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Stack(
        children: [
          if (vm.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (vm.error != null)
            _errorState(vm.error!)
          else if (vm.account == null)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heroCard(vm.account!),
                        const SizedBox(height: 16),
                        _infoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Association Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _slpaNameRow(vm.account!),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _infoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _memberInfoSection(vm.account!),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPadding),
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          elevation: 12,
                          borderRadius: BorderRadius.circular(20),
                          shadowColor: const Color(
                            0xFF8EA1D1,
                          ).withValues(alpha: 0.18),
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _editMode
                                    ? const Color(0xFFE9F0FF)
                                    : _accentBlue.withValues(alpha: 0.14),
                                foregroundColor: _editMode
                                    ? _textPrimary
                                    : _accentBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (!_editMode) {
                                    firstNameCtrl.text = vm.account!.firstName;
                                    middleNameCtrl.text =
                                        vm.account!.middleName ?? '';
                                    lastNameCtrl.text = vm.account!.lastName;
                                  }
                                  _editMode = !_editMode;
                                });
                              },
                              child: Text(
                                _editMode ? 'Cancel' : 'Edit Profile',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_editMode) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Material(
                            elevation: 14,
                            borderRadius: BorderRadius.circular(20),
                            shadowColor: const Color(
                              0xFF8EA1D1,
                            ).withValues(alpha: 0.22),
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accentBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () async {
                                  String? imagePath = vm.account!.profileImage;
                                  if (_selectedImage != null) {
                                    final dir =
                                        await getApplicationDocumentsDirectory();
                                    final fileName =
                                        DateTime.now().millisecondsSinceEpoch;
                                    final savedFile = await _selectedImage!.copy(
                                      '${dir.path}/profile_$fileName.jpg',
                                    );
                                    imagePath = savedFile.path;
                                  }

                                  final updated = vm.account!.copyWith(
                                    firstName: firstNameCtrl.text.trim().isEmpty
                                        ? vm.account!.firstName
                                        : firstNameCtrl.text.trim(),
                                    middleName:
                                        middleNameCtrl.text.trim().isEmpty
                                        ? null
                                        : middleNameCtrl.text.trim(),
                                    lastName: lastNameCtrl.text.trim().isEmpty
                                        ? vm.account!.lastName
                                        : lastNameCtrl.text.trim(),
                                    profileImage: imagePath,
                                  );

                                  final success = await vm.updateProfile(updated);
                                  if (!success) return;

                                  setState(() {
                                    _editMode = false;
                                    _selectedImage = null;
                                  });
                                },
                                child: const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _errorState(Object err) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              'Error: $err',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => ref.read(profileViewModelProvider).loadAccount(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentBlue,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroCard(Account account) {
    final hasImage = account.profileImage != null || _selectedImage != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
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
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 98,
                height: 98,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.70),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 49,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : account.profileImage != null
                          ? FileImage(File(account.profileImage!))
                          : null,
                  child: !hasImage
                      ? const Icon(
                          Icons.groups_rounded,
                          size: 42,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              if (_editMode)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 18,
                        color: _accentBlue,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            [
              account.firstName,
              account.middleName,
              account.lastName,
            ].where((part) => (part ?? '').trim().isNotEmpty).join(' '),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            account.slpaName,
            style: const TextStyle(
              color: Color(0xFFE8F2FF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberInfoSection(Account account) {
    if (_editMode) {
      return Column(
        children: [
          _profileField(
            controller: firstNameCtrl,
            label: 'First Name',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 12),
          _profileField(
            controller: middleNameCtrl,
            label: 'Middle Name',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 12),
          _profileField(
            controller: lastNameCtrl,
            label: 'Last Name',
            icon: Icons.badge_rounded,
          ),
          const SizedBox(height: 12),
          _readonlyRow(
            icon: Icons.phone_android_rounded,
            title: 'Mobile Number',
            subtitle: '',
            value: account.mobileNumber,
          ),
        ],
      );
    }

    return Column(
      children: [
        _readonlyRow(
          icon: Icons.person_outline_rounded,
          title: 'First Name',
          subtitle: '',
          value: account.firstName,
        ),
        const SizedBox(height: 12),
        _readonlyRow(
          icon: Icons.person_outline_rounded,
          title: 'Middle Name',
          subtitle: '',
          value: (account.middleName ?? '').trim().isEmpty
              ? 'Not set'
              : account.middleName!,
        ),
        const SizedBox(height: 12),
        _readonlyRow(
          icon: Icons.badge_rounded,
          title: 'Last Name',
          subtitle: '',
          value: account.lastName,
        ),
        const SizedBox(height: 12),
        _readonlyRow(
          icon: Icons.phone_android_rounded,
          title: 'Mobile Number',
          subtitle: '',
          value: account.mobileNumber,
        ),
      ],
    );
  }

  Widget _slpaNameRow(Account account) {
    return Column(
      children: [
        _readonlyRow(
          icon: Icons.groups_rounded,
          title: 'SLPA Name',
          subtitle: 'Association / organization name',
          value: account.slpaName,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _readonlyRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _accentBlue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _accentBlue, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: _textPrimary,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        prefixIcon: Icon(icon),
        prefixIconColor: _accentBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _accentBlue, width: 1.6),
        ),
      ),
    );
  }

  Widget _infoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8EA1D1).withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
