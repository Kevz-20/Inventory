import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/app_colors.dart';
import '../../models/account_model.dart';
import '../../providers/profile_view_model_provider.dart';
import '../widgets/header.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editMode = false;
  bool _editingAnswer = false;

  late final TextEditingController answerCtrl;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    answerCtrl = TextEditingController();
  }

  @override
  void dispose() {
    answerCtrl.dispose();
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

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: const AppHeader(title: "Profile", showBackButton: true),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
              ? _errorState(vm.error!)
              : vm.account == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _profileImage(vm.account!),
                          const SizedBox(height: 25),

                          _sectionTitle('Account Information'),

                          _infoCard([
                            _infoRow(
                              Icons.numbers,
                              'Mobile Number',
                              vm.account!.mobileNumber,
                            ),
                            _securityAnswerRow(vm.account!),
                          ]),

                          const SizedBox(height: 20),

                          /// EDIT / CANCEL BUTTON
                          ElevatedButton(
                            style: _primaryLightButtonStyle,
                            onPressed: () {
                              setState(() {
                                _editMode = !_editMode;
                                _editingAnswer = false;
                              });
                            },
                            child: Text(_editMode ? 'Cancel' : 'Edit Profile'),
                          ),

                          /// SAVE CHANGES BUTTON
                          if (_editMode) ...[
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: _primaryButtonStyle,
                              onPressed: () async {
                                String? imagePath = vm.account!.profileImage;

                                if (_selectedImage != null) {
                                  final dir = await getApplicationDocumentsDirectory();
                                  final fileName = DateTime.now().millisecondsSinceEpoch;
                                  final savedFile = await _selectedImage!.copy(
                                    '${dir.path}/profile_$fileName.jpg',
                                  );
                                  imagePath = savedFile.path;
                                }

                                final updated = vm.account!.copyWith(
                                  securityAnswer: answerCtrl.text,
                                  profileImage: imagePath,
                                );

                                final success = await vm.updateProfile(updated);
                                if (!success) return;

                                setState(() {
                                  _editingAnswer = false;
                                  _editMode = false;
                                  _selectedImage = null;
                                });
                              },
                              child: const Text('Save Changes'),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _errorState(Object err) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $err'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => ref.read(profileViewModelProvider).loadAccount(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );

  Widget _profileImage(Account account) => Center(
        child: Stack(
          children: [
            CircleAvatar(
              radius: 55,
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : account.profileImage != null
                      ? FileImage(File(account.profileImage!))
                      : null,
              child: account.profileImage == null && _selectedImage == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            if (_editMode)
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _securityAnswerRow(Account account) => Column(
        children: [
          Row(
            children: [
              Icon(Icons.question_answer, color: AppColors.primaryLight),
              const SizedBox(width: 10),
              const Expanded(child: Text('Security Answer')),
              if (!_editingAnswer) ...[
                Text(
                  account.securityAnswer ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_editMode)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () {
                      setState(() {
                        answerCtrl.text = account.securityAnswer ?? '';
                        _editingAnswer = true;
                      });
                    },
                  ),
              ],
            ],
          ),
          if (_editingAnswer)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: answerCtrl,
                decoration: const InputDecoration(
                  hintText: 'Enter new security answer',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          const Divider(height: 20),
        ],
      );
}

/// ---------------- UI HELPERS ----------------
final _primaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: AppColors.primary,
  minimumSize: const Size(double.infinity, 48),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

final _primaryLightButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: AppColors.primaryLight,
  minimumSize: const Size(double.infinity, 48),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

Widget _sectionTitle(String title) => Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );

Widget _infoCard(List<Widget> children) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );

Widget _infoRow(IconData icon, String label, String value) => Column(
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryLight),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const Divider(height: 20),
      ],
    );
