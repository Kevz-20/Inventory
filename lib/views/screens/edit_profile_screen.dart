import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/account_model.dart';
import '../../providers/profile_view_model_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends ConsumerState<EditProfileScreen> {
  late final TextEditingController associationCtrl;
  late final TextEditingController answerCtrl;

  File? _selectedImage;

  @override
  void initState() {
    super.initState();

    final vm = ref.read(profileViewModelProvider).value;
    final acc = vm?.account;

    associationCtrl =
        TextEditingController(text: acc?.associationName ?? '');
    answerCtrl =
        TextEditingController(text: acc?.securityAnswer ?? '');
  }

  @override
  void dispose() {
    associationCtrl.dispose();
    answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (!mounted) return;

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Widget _artisticInput({
    required TextEditingController controller,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
        ),
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vmAsync = ref.watch(profileViewModelProvider);
    final vm = vmAsync.value;

    if (vm == null || vm.account == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final account = vm.account!;

    if (associationCtrl.text.isEmpty) {
      associationCtrl.text = account.associationName ?? '';
      answerCtrl.text = account.securityAnswer ?? '';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : account.profileImage != null
                            ? FileImage(
                                File(account.profileImage!))
                            : null,
                    child: account.profileImage == null &&
                            _selectedImage == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
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
            ),
            const SizedBox(height: 20),
            _artisticInput(
              controller: associationCtrl,
              label: 'Association',
            ),
            _artisticInput(
              controller: answerCtrl,
              label: 'Security Answer',
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () async {
                String? imagePath = account.profileImage;

                if (_selectedImage != null) {
                  final dir =
                      await getApplicationDocumentsDirectory();
                  final fileName =
                      DateTime.now().millisecondsSinceEpoch;
                  final savedFile =
                      await _selectedImage!.copy(
                    '${dir.path}/profile_$fileName.jpg',
                  );
                  imagePath = savedFile.path;
                }

                final updated = account.copyWith(
                  associationName: associationCtrl.text,
                  securityAnswer: answerCtrl.text,
                  profileImage: imagePath,
                );

                final success = await vm.updateProfile(updated);

                if (!context.mounted) return;

                if (success) {
                Navigator.of(context).pop();
                }

              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
