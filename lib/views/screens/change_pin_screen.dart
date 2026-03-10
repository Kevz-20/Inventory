import 'package:dswd_slp/core/app_colors.dart';
import 'package:dswd_slp/view_models/change_pin_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/header.dart';

final changePinProvider = ChangeNotifierProvider.autoDispose(
  (ref) => ChangePinViewModel(),
);

class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  // ── Reusable text input ────────────────────────────────────────────────────
  Widget inputField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required double screenWidth,
    VoidCallback? toggleVisibility,
    int maxLength = 50,
    bool onlyNumbers = false,
    bool showError = false,
    bool readOnly = false,
  }) {
    final bool isError = showError && controller.text.isEmpty;
    final double fieldHeight = screenWidth < 360 ? 56 : 64;

    return SizedBox(
      height: fieldHeight,
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
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: screenWidth < 360 ? 13 : 15,
        ),
        decoration: InputDecoration(
          counterText: '',
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: screenWidth < 360 ? 12 : 14,
          ),
          filled: true,
          fillColor: readOnly ? const Color(0xFFF2F4F3) : Colors.white,
          suffixIcon: toggleVisibility == null
              ? null
              : IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.primary,
                    size: screenWidth < 360 ? 18 : 22,
                  ),
                  onPressed: toggleVisibility,
                ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth < 360 ? 10 : 12,
            vertical: screenWidth < 360 ? 12 : 16,
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

  // ── Verified / locked badge ────────────────────────────────────────────────
  Widget _verifiedBadge({
    required String text,
    required double screenWidth,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth < 360 ? 10 : 12,
        vertical: screenWidth < 360 ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline,
              color: AppColors.primary, size: screenWidth < 360 ? 18 : 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: screenWidth < 360 ? 13 : 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Security question hint card ────────────────────────────────────────────
  /// Shows the question chosen during account creation above the answer field,
  /// so the user is never left guessing what to type.
  /// Renders the question as a plain label above the answer TextField —
  /// matching the standard form field layout from the design.
  Widget _securityQuestionField({
    required String question,
    required TextEditingController controller,
    required double screenWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(
            fontSize: screenWidth < 360 ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: screenWidth < 360 ? 56 : 64,
          child: TextField(
            controller: controller,
            maxLength: 50,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: screenWidth < 360 ? 13 : 15,
            ),
            decoration: InputDecoration(
              counterText: '',
              labelText: 'Security Answer',
              labelStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: screenWidth < 360 ? 12 : 14,
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(
                Icons.help_outline_rounded,
                color: AppColors.primary,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth < 360 ? 10 : 12,
                vertical: screenWidth < 360 ? 12 : 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.border, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for successful PIN change — show snackbar then navigate.
    // Done here (in the widget) so GoRouter has a valid context to work with.
    ref.listen<ChangePinViewModel>(changePinProvider, (_, vm) {
      if (vm.isPinChangedSuccessfully) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN changed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        vm.clearAll();
        context.go('/settings');
      }
    });

    final vm = ref.watch(changePinProvider);

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth < 360;
    final isNarrow = screenWidth < 430;

    final double horizontalPadding =
        isSmallScreen ? 12 : isNarrow ? 16 : 24;
    final double cardPadding = isSmallScreen ? 14 : 20;
    final double itemSpacing = isSmallScreen ? 12 : 16;

    final title = !vm.isMobileVerified
        ? 'Verify your number'
        : !vm.isSecurityVerified
            ? 'Confirm security answer'
            : !vm.isOldPinVerified
                ? 'Verify old PIN'
                : 'Set a new PIN';

    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      appBar: const AppHeader(title: 'Change PIN', showBackButton: true),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF4F1), AppColors.surface],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  horizontalPadding,
                  horizontalPadding,
                  mediaQuery.viewInsets.bottom + horizontalPadding,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Container(
                      padding: EdgeInsets.all(cardPadding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(isSmallScreen ? 16 : 20),
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
                          // ── Title ────────────────────────────────────
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Follow each step to securely update your PIN.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                          if (vm.isOldPinVerified) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Ready to save your new PIN.',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                          ],

                          SizedBox(height: itemSpacing + 4),

                          // ── Mobile Number ────────────────────────────
                          inputField(
                            controller: vm.mobileController,
                            label: 'Mobile Number',
                            obscureText: false,
                            screenWidth: screenWidth,
                            maxLength: 11,
                            onlyNumbers: true,
                            readOnly: vm.isMobileVerified,
                          ),

                          // ── Security Question + Answer ───────────────
                          if (vm.isMobileVerified) ...[
                            SizedBox(height: itemSpacing),

                            if (!vm.isSecurityVerified) ...[
                              // Question as label + answer field in one widget
                              if (vm.userSecurityQuestion != null &&
                                  vm.userSecurityQuestion!.isNotEmpty)
                                _securityQuestionField(
                                  question: vm.userSecurityQuestion!,
                                  controller: vm.answerController,
                                  screenWidth: screenWidth,
                                )
                              else
                                inputField(
                                  controller: vm.answerController,
                                  label: 'Security Answer',
                                  obscureText: false,
                                  screenWidth: screenWidth,
                                  maxLength: 50,
                                ),
                            ] else
                              _verifiedBadge(
                                text: vm.answerController.text,
                                screenWidth: screenWidth,
                              ),
                          ],

                          // ── Old PIN ──────────────────────────────────
                          if (vm.isSecurityVerified) ...[
                            SizedBox(height: itemSpacing),
                            if (!vm.isOldPinVerified)
                              inputField(
                                controller: vm.oldPinController,
                                label: 'Old PIN',
                                obscureText: !vm.showOldPin,
                                toggleVisibility: vm.toggleOldPin,
                                screenWidth: screenWidth,
                                maxLength: 4,
                                onlyNumbers: true,
                              )
                            else
                              _verifiedBadge(
                                text: 'Old PIN verified',
                                screenWidth: screenWidth,
                              ),
                          ],

                          // ── New PIN ──────────────────────────────────
                          if (vm.isOldPinVerified) ...[
                            SizedBox(height: itemSpacing),
                            inputField(
                              controller: vm.newPinController,
                              label: 'New PIN',
                              obscureText: !vm.showNewPin,
                              toggleVisibility: vm.toggleNewPin,
                              screenWidth: screenWidth,
                              maxLength: 4,
                              onlyNumbers: true,
                            ),
                          ],

                          SizedBox(height: itemSpacing + 8),

                          // ── Action Button ────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: isSmallScreen ? 44 : 52,
                            child: vm.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      backgroundColor: AppColors.primary,
                                      foregroundColor:
                                          AppColors.textOnPrimary,
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
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 16,
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
      ),
    );
  }
}