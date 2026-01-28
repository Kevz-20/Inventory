// ignore_for_file: deprecated_member_use

import 'package:dswd_slp/core/app_colors.dart';
import 'package:dswd_slp/view_models/change_pin_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  }) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glow = 0.4 + 0.6 * _glowController.value; // neon glow intensity

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(glow),
                blurRadius: 12 * glow,
                spreadRadius: 1,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            maxLength: maxLength,
            style: const TextStyle(color: Colors.black),
            keyboardType: onlyNumbers
                ? TextInputType.number
                : TextInputType.text,
            inputFormatters: onlyNumbers
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(maxLength),
                  ]
                : [LengthLimitingTextInputFormatter(maxLength)],
            decoration: InputDecoration(
              counterText: '',
              labelText: label,
              labelStyle: const TextStyle(color: Colors.black54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.95),
              suffixIcon: toggleVisibility == null
                  ? null
                  : IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility : Icons.visibility_off,
                        color: const Color.fromARGB(255, 21, 65, 22),
                      ),
                      onPressed: toggleVisibility,
                    ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.black.withOpacity(glow), // neon black
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color.fromARGB(
                    255,
                    15,
                    50,
                    33,
                  ).withOpacity(0.8), // neon focus
                  width: 2.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(changePinProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Change PIN', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
