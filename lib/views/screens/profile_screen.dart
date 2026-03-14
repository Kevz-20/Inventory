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
  late final TextEditingController slpaNameCtrl;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    slpaNameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    slpaNameCtrl.dispose();
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
      appBar: const AppHeader(title: 'Profile', showBackButton: true),
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
                          _sectionTitle('Association Information'),
                          _infoCard([
                            _slpaNameRow(vm.account!),
                          ]),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: _primaryLightButtonStyle,
                            onPressed: () {
                              setState(() {
                                if (!_editMode) {
                                  slpaNameCtrl.text = vm.account!.slpaName;
                                }
                                _editMode = !_editMode;
                              });
                            },
                            child: Text(_editMode ? 'Cancel' : 'Edit Association'),
                          ),
                          if (_editMode) ...[
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: _primaryButtonStyle,
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
                                  slpaName: slpaNameCtrl.text.trim().isEmpty
                                      ? vm.account!.slpaName
                                      : slpaNameCtrl.text.trim(),
                                  profileImage: imagePath,
                                );

                                final success = await vm.updateProfile(updated);
                                if (!success) return;

                                setState(() {
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
                  ? const Icon(Icons.groups_rounded, size: 50)
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

  Widget _slpaNameRow(Account account) => Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.groups_rounded, color: AppColors.primaryLight),
              const SizedBox(width: 10),
              const Expanded(child: Text('SLPA Name')),
              if (!_editMode)
                Flexible(
                  child: Text(
                    account.slpaName,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          if (_editMode)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: slpaNameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Enter SLPA name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
        ],
      );
}

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
