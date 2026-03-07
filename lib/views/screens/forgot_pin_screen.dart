import 'package:dswd_slp/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../view_models/forgot_pin_view_model.dart';
import '../widgets/header.dart';

class ForgotPinScreen extends ConsumerStatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  ConsumerState<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends ConsumerState<ForgotPinScreen> {
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    int maxLength = 50,
    bool obscureText = false,
    bool onlyNumbers = false,
    IconData? icon,
    bool readOnly = false,
  }) {
    return SizedBox(
      height: 64,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        readOnly: readOnly,
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
          prefixIcon: icon == null ? null : Icon(icon, color: AppColors.primary),
          filled: true,
          fillColor: readOnly ? const Color(0xFFF2F4F3) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(forgotPinViewModelProvider);

    ref.listen<String?>(
      forgotPinViewModelProvider.select((state) => state.errorMessage),
      (_, errorMessage) {
      if (!mounted) return;
      if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(forgotPinViewModelProvider).clearError();
      }
    });

    final title = vm.account == null
        ? 'Verify your number'
        : !vm.isSecurityVerified
            ? 'Confirm security answer'
            : 'Set a new PIN';
    final isMobileLocked =
        vm.account != null && vm.account!.mobileNumber == vm.mobileController.text.trim();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Forgot PIN', showBackButton: true),
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
                            'Follow each step to reset your PIN securely.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          if (vm.isSecurityVerified) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Reave your new PIN.',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          _inputField(
                            controller: vm.mobileController,
                            label: 'Mobile Number',
                            maxLength: 11,
                            onlyNumbers: true,
                            icon: Icons.phone_android,
                            readOnly: isMobileLocked,
                          ),
                          if (vm.account != null) ...[
                            const SizedBox(height: 16),
                            FutureBuilder<String>(
                              future: vm.securityQuestion,
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    snapshot.data!,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (!vm.isSecurityVerified)
                              _inputField(
                                controller: vm.answerController,
                                label: 'Security Answer',
                                icon: Icons.help_outline,
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F4F3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.lock_outline,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        vm.answerController.text,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                          if (vm.isSecurityVerified) ...[
                            const SizedBox(height: 16),
                            _inputField(
                              controller: vm.newPinController,
                              label: 'New PIN',
                              maxLength: 4,
                              obscureText: true,
                              onlyNumbers: true,
                              icon: Icons.lock_outline,
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: vm.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(color: AppColors.primary),
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
                                    onPressed: () async {
                                      final inputMobile = vm.mobileController.text.trim();
                                      final hasMatchingLoadedAccount =
                                          vm.account != null && vm.account!.mobileNumber == inputMobile;

                                      if (!hasMatchingLoadedAccount) {
                                        await vm.fetchAccount();
                                      } else if (!vm.isSecurityVerified) {
                                        vm.validateAnswer();
                                      } else {
                                        final success = await vm.updatePin();
                                        if (success && context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('PIN saved successfully!'),
                                              backgroundColor: AppColors.success,
                                            ),
                                          );
                                          await Future.delayed(
                                            const Duration(milliseconds: 700),
                                          );
                                          if (!context.mounted) return;
                                          context.go('/login');
                                        }
                                      }
                                    },
                                    child: Text(
                                      vm.account == null
                                          ? 'Verify Number'
                                          : vm.isSecurityVerified
                                              ? 'Save PIN'
                                              : 'Verify Answer',
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
