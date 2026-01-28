// ignore_for_file: deprecated_member_use

import 'package:dswd_slp/core/app_colors.dart';
import 'package:dswd_slp/view_models/change_pin_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/header.dart';

final changePinProvider = ChangeNotifierProvider((ref) => ChangePinViewModel());

class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Widget inputField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    VoidCallback? toggleVisibility,
    int maxLength = 50,
    bool onlyNumbers = false,
    bool showError = false,
  }) {
    final bool isError = showError && controller.text.isEmpty;

    return SizedBox(
      height: 60,
      child: TextField(
        controller: controller,
        obscureText: obscureText, // ✅ source of truth
        maxLength: maxLength,
        keyboardType: onlyNumbers ? TextInputType.number : TextInputType.text,
        inputFormatters: onlyNumbers
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(maxLength),
              ]
            : [LengthLimitingTextInputFormatter(maxLength)],
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: '',
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          suffixIcon: toggleVisibility == null
              ? null
              : IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons
                              .visibility_off // 🔒 hidden first
                        : Icons.visibility, // 👁 shown
                    color: Colors.grey.shade600,
                  ),
                  onPressed: toggleVisibility,
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isError ? Colors.red : Colors.grey.shade400,
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isError ? Colors.red : AppColors.primary,
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(changePinProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppHeader(title: "Change PIN", showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            inputField(
              controller: vm.mobileController,
              label: 'Mobile Number',
              obscureText: false,
              toggleVisibility: null,
              maxLength: 11,
              onlyNumbers: true,
            ),
            const SizedBox(height: 16),
            inputField(
              controller: vm.oldPinController,
              label: 'Old PIN',
              obscureText: !vm.showOldPin,
              toggleVisibility: vm.toggleOldPin,
              maxLength: 4,
              onlyNumbers: true,
            ),
            const SizedBox(height: 16),
            inputField(
              controller: vm.newPinController,
              label: 'New PIN',
              obscureText: !vm.showNewPin,
              toggleVisibility: vm.toggleNewPin,
              maxLength: 4,
              onlyNumbers: true,
            ),
            const SizedBox(height: 16),
            inputField(
              controller: vm.answerController,
              label: 'Security Answer',
              obscureText: false,
              toggleVisibility: null,
              maxLength: 50,
              onlyNumbers: false,
            ),
            const SizedBox(height: 32),
            vm.isLoading
                ? const CircularProgressIndicator(
                    color: Color.fromARGB(255, 9, 43, 10),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: AppColors.primary,
                      elevation: 12,
                    ),
                    onPressed: () => vm.changePin(context),
                    child: const Text(
                      'Change PIN',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
