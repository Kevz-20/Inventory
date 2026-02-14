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

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
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
      height: 64,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        maxLength: maxLength,
        keyboardType: onlyNumbers ? TextInputType.number : TextInputType.text,
        inputFormatters: onlyNumbers
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(maxLength),
              ]
            : [LengthLimitingTextInputFormatter(maxLength)],
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          counterText: '',
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: toggleVisibility == null
              ? null
              : IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.primary,
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
              color: isError ? AppColors.error : AppColors.border,
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isError ? AppColors.error : AppColors.primary,
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
    final title = !vm.isMobileVerified
        ? 'Verify your number'
        : !vm.isSecurityVerified
            ? 'Confirm security answer'
            : !vm.isOldPinVerified
                ? 'Verify old PIN'
                : 'Set a new PIN';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Change PIN', showBackButton: true),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF4F1), AppColors.surface],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFCFE5DE)),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Follow each step to securely update your PIN.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          if (vm.isOldPinVerified) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Ready to save your new PIN.',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          inputField(
                            controller: vm.mobileController,
                            label: 'Mobile Number',
                            obscureText: false,
                            toggleVisibility: null,
                            maxLength: 11,
                            onlyNumbers: true,
                          ),
                          if (vm.isMobileVerified) ...[
                            const SizedBox(height: 16),
                            inputField(
                              controller: vm.answerController,
                              label: 'Security Answer',
                              obscureText: false,
                              toggleVisibility: null,
                              maxLength: 50,
                              onlyNumbers: false,
                            ),
                          ],
                          if (vm.isSecurityVerified) ...[
                            const SizedBox(height: 16),
                            inputField(
                              controller: vm.oldPinController,
                              label: 'Old PIN',
                              obscureText: !vm.showOldPin,
                              toggleVisibility: vm.toggleOldPin,
                              maxLength: 4,
                              onlyNumbers: true,
                            ),
                          ],
                          if (vm.isOldPinVerified) ...[
                            const SizedBox(height: 16),
                            inputField(
                              controller: vm.newPinController,
                              label: 'New PIN',
                              obscureText: !vm.showNewPin,
                              toggleVisibility: vm.toggleNewPin,
                              maxLength: 4,
                              onlyNumbers: true,
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: vm.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.textOnPrimary,
                                      elevation: 3,
                                    ),
                                    onPressed: () {
                                      if (!vm.isMobileVerified) {
                                        vm.verifyMobile(context);
                                      } else if (!vm.isSecurityVerified) {
                                        vm.verifySecurityAnswer(context);
                                      } else if (!vm.isOldPinVerified) {
                                        vm.verifyOldPin(context);
                                      } else {
                                        vm.saveNewPin(context);
                                      }
                                    },
                                    child: Text(
                                      !vm.isMobileVerified
                                          ? 'Verify Number'
                                          : !vm.isSecurityVerified
                                              ? 'Verify Answer'
                                              : !vm.isOldPinVerified
                                                  ? 'Verify Old PIN'
                                                  : 'Save PIN',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
