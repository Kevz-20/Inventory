// ignore_for_file: deprecated_member_use

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../view_models/create_account_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../core/app_colors.dart';
import '../widgets/header.dart';
import '../../repositories/account_repository.dart';
import '../../models/account_model.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  bool pinVisible = false;
  bool confirmPinVisible = false;

  final accountRepo = AccountRepository();
  final nameFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\.-]'));

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(createAccountProvider);
    final vmNotifier = ref.read(createAccountProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        // Same approach as other pages: phone->tablet scaling, clamped.
        final double scale = (w / 390).clamp(0.90, 1.20);

        final double padH = (20 * scale).clamp(14, 24);
        final double padV = (20 * scale).clamp(14, 24);

        final double gap15 = (15 * scale).clamp(10, 18);
        final double gap25 = (25 * scale).clamp(16, 28);

        final double btnH = (50 * scale).clamp(46, 56);
        final double btnFs = (16 * scale).clamp(14, 18);

        final double labelFs = (14 * scale).clamp(13, 16);
        final double hintFs = (14 * scale).clamp(12.5, 16);
        final double errorFs = (12 * scale).clamp(11, 13);

        final double fieldVPad = (14 * scale).clamp(12, 16);
        final double fieldHPad = (12 * scale).clamp(10, 14);

        final double radius = (10 * scale).clamp(10, 14);

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: const AppHeader(title: "Bag-ong Account", showBackButton: true),

          // ==================== FIXED BOTTOM BUTTON (RESPONSIVE) ====================
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padH, vertical: (12 * scale).clamp(10, 14)),
              child: SizedBox(
                width: double.infinity,
                height: btnH,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        !vm.isLoading ? AppColors.primary : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular((12 * scale).clamp(10, 14)),
                    ),
                  ),
                  onPressed: !vm.isLoading
                      ? () async {
                          vmNotifier.setLoading(true);

                          bool success = await vm.createAccount(context);

                          vmNotifier.setLoading(false);

                          if (success) {
                            if (!context.mounted) return;

                            final account = Account(
                              id: 0,
                              firstName: vm.firstNameController.text.trim(),
                              middleName:
                                  vm.middleNameController.text.trim().isEmpty
                                      ? null
                                      : vm.middleNameController.text.trim(),
                              lastName: vm.lastNameController.text.trim(),
                              mobileNumber: vm.mobileController.text.trim(),
                              pin: vm.pinController.text.trim(),
                              securityAnswer: vm.answerController.text.trim(),
                            );
                            await accountRepo.updateAccount(account);

                            vm.clearFields();

                            final loginVM = ref.read(loginViewModelProvider);
                            await loginVM.loadSavedMobile();

                            if (!context.mounted) return;
                            context.go('/login');
                          }
                        }
                      : null,
                  child: vm.isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        )
                      : Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: btnFs,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),

          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            child: Form(
              key: vm.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================== Response message ====================
                  if (vm.errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: (8 * scale).clamp(8, 10),
                        horizontal: (12 * scale).clamp(10, 14),
                      ),
                      margin: EdgeInsets.only(bottom: (10 * scale).clamp(8, 14)),
                      decoration: BoxDecoration(
                        color: vm.isSuccessMessage
                            ? AppColors.success
                            : AppColors.error,
                        borderRadius: BorderRadius.circular((8 * scale).clamp(8, 12)),
                      ),
                      child: Text(
                        vm.errorMessage!,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: (13.5 * scale).clamp(12.5, 16),
                        ),
                      ),
                    ),

                  // ==================== MOBILE NUMBER ====================
                  buildLabel("Mobile Number", fontSize: labelFs),
                  buildTextField(
                    controller: vm.mobileController,
                    hint: "09XXXXXXXXX",
                    maxLength: 11,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    errorText: vm.mobileError,
                    onChanged: (_) =>
                        vmNotifier.clearFieldError(vm.mobileController),
                    scale: scale,
                    hintFs: hintFs,
                    errorFs: errorFs,
                    fieldHPad: fieldHPad,
                    fieldVPad: fieldVPad,
                    radius: radius,
                  ),
                  SizedBox(height: gap15),

                  // ==================== PIN ====================
                  buildLabel("PIN", fontSize: labelFs),
                  Row(
                    children: [
                      Expanded(
                        child: buildTextField(
                          controller: vm.pinController,
                          hint: "Enter 4-digit PIN",
                          obscureText: !pinVisible,
                          maxLength: 4,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          keyboardType: TextInputType.number,
                          errorText: vm.pinError,
                          onChanged: (_) =>
                              vmNotifier.clearFieldError(vm.pinController),
                          suffixIcon: InkWell(
                            onTap: () => setState(() => pinVisible = !pinVisible),
                            child: Icon(
                              pinVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                              size: (22 * scale).clamp(20, 26),
                            ),
                          ),
                          scale: scale,
                          hintFs: hintFs,
                          errorFs: errorFs,
                          fieldHPad: fieldHPad,
                          fieldVPad: fieldVPad,
                          radius: radius,
                        ),
                      ),
                      SizedBox(width: (12 * scale).clamp(10, 16)),
                      Expanded(
                        child: buildTextField(
                          controller: vm.confirmPinController,
                          hint: "Re-enter PIN",
                          obscureText: !confirmPinVisible,
                          maxLength: 4,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          keyboardType: TextInputType.number,
                          errorText: vm.confirmPinError,
                          onChanged: (_) =>
                              vmNotifier.clearFieldError(vm.confirmPinController),
                          suffixIcon: InkWell(
                            onTap: () => setState(
                              () => confirmPinVisible = !confirmPinVisible,
                            ),
                            child: Icon(
                              confirmPinVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                              size: (22 * scale).clamp(20, 26),
                            ),
                          ),
                          scale: scale,
                          hintFs: hintFs,
                          errorFs: errorFs,
                          fieldHPad: fieldHPad,
                          fieldVPad: fieldVPad,
                          radius: radius,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: gap15),

                  // ==================== FIRST NAME ====================
                  buildLabel("First Name", fontSize: labelFs),
                  buildTextField(
                    controller: vm.firstNameController,
                    hint: "Juan",
                    errorText: vm.firstNameError,
                    inputFormatters: [nameFormatter],
                    onChanged: (_) =>
                        vmNotifier.clearFieldError(vm.firstNameController),
                    scale: scale,
                    hintFs: hintFs,
                    errorFs: errorFs,
                    fieldHPad: fieldHPad,
                    fieldVPad: fieldVPad,
                    radius: radius,
                  ),
                  SizedBox(height: gap15),

                  // ==================== MIDDLE NAME ====================
                  buildLabel("Middle Name (Optional)", fontSize: labelFs),
                  buildTextField(
                    controller: vm.middleNameController,
                    hint: "Dela",
                    errorText: vm.middleNameError,
                    inputFormatters: [nameFormatter],
                    onChanged: (_) =>
                        vmNotifier.clearFieldError(vm.middleNameController),
                    scale: scale,
                    hintFs: hintFs,
                    errorFs: errorFs,
                    fieldHPad: fieldHPad,
                    fieldVPad: fieldVPad,
                    radius: radius,
                  ),
                  SizedBox(height: gap15),

                  // ==================== LAST NAME ====================
                  buildLabel("Last Name", fontSize: labelFs),
                  buildTextField(
                    controller: vm.lastNameController,
                    hint: "Cruz Jr.",
                    errorText: vm.lastNameError,
                    inputFormatters: [nameFormatter],
                    onChanged: (_) =>
                        vmNotifier.clearFieldError(vm.lastNameController),
                    scale: scale,
                    hintFs: hintFs,
                    errorFs: errorFs,
                    fieldHPad: fieldHPad,
                    fieldVPad: fieldVPad,
                    radius: radius,
                  ),
                  SizedBox(height: gap15),

                  // ==================== SECURITY QUESTION ====================
                  buildLabel("Security Question (for PIN reset)", fontSize: labelFs),
                  DropdownButtonFormField<String>(
                    initialValue: vm.selectedQuestion,
                    hint: Text(
                      "Pili ug pangutana",
                      style: TextStyle(fontSize: hintFs, fontWeight: FontWeight.w600),
                    ),
                    dropdownColor: Colors.white,
                    decoration: inputDecorationWithError(
                      vm.questionError,
                      scale: scale,
                      errorFs: errorFs,
                      fieldHPad: fieldHPad,
                      fieldVPad: fieldVPad,
                      radius: radius,
                    ),
                    isExpanded: true,
                    items: vm.questions
                        .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                        .toList(),
                    onChanged: (value) {
                      vmNotifier.setSelectedQuestion(value);
                      if (vm.answerController.text.isNotEmpty) {
                        vmNotifier.clearFieldError(vm.answerController);
                      }
                    },
                  ),
                  SizedBox(height: gap15),

                  // ==================== SECURITY ANSWER ====================
                  buildLabel("Tubag (Answer)", fontSize: labelFs),
                  buildTextField(
                    controller: vm.answerController,
                    hint: "Isulat ang imong tubag",
                    errorText: vm.answerError,
                    onChanged: (_) =>
                        vmNotifier.clearFieldError(vm.answerController),
                    scale: scale,
                    hintFs: hintFs,
                    errorFs: errorFs,
                    fieldHPad: fieldHPad,
                    fieldVPad: fieldVPad,
                    radius: radius,
                  ),
                  SizedBox(height: gap25),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== HELPERS (UI only updated) ====================

  Widget buildLabel(String text, {double? fontSize}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: fontSize ?? 14,
          ),
        ),
      );

  Widget buildTextField({
    required TextEditingController controller,
    String? hint,
    bool obscureText = false,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    String? errorText,
    Function(String)? onChanged,
    Widget? suffixIcon,

    // responsive params (UI only)
    double? scale,
    double? hintFs,
    double? errorFs,
    double? fieldHPad,
    double? fieldVPad,
    double? radius,
  }) {
    final s = (scale ?? 1.0).clamp(0.9, 1.2);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType ?? TextInputType.text,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: hintFs ?? (14 * s).clamp(12.5, 16)),
        errorText: errorText,
        errorStyle: TextStyle(
          color: AppColors.error,
          fontSize: errorFs ?? (12 * s).clamp(11, 13),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: fieldHPad ?? (12 * s).clamp(10, 14),
          vertical: fieldVPad ?? (14 * s).clamp(12, 16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius ?? (10 * s).clamp(10, 14)),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius ?? (10 * s).clamp(10, 14)),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius ?? (10 * s).clamp(10, 14)),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius ?? (10 * s).clamp(10, 14)),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  InputDecoration inputDecorationWithError(
    String? errorText, {
    double? scale,
    double? errorFs,
    double? fieldHPad,
    double? fieldVPad,
    double? radius,
  }) {
    final s = (scale ?? 1.0).clamp(0.9, 1.2);

    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      errorText: errorText,
      errorStyle: TextStyle(
        color: AppColors.error,
        fontSize: errorFs ?? (12 * s).clamp(11, 13),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: fieldHPad ?? (12 * s).clamp(10, 14),
        vertical: fieldVPad ?? (14 * s).clamp(12, 16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius ?? (10 * s).clamp(10, 14)),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius ?? (10 * s).clamp(10, 14)),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius ?? (10 * s).clamp(10, 14)),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius ?? (10 * s).clamp(10, 14)),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }
}