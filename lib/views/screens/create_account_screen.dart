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

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(createAccountProvider);
    final vmNotifier = ref.read(createAccountProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: "Bag-ong Account", showBackButton: true),
      // ==================== FIXED BOTTOM BUTTON ====================
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: !vm.isLoading
                    ? AppColors.primary
                    : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: !vm.isLoading
                  ? () async {
                      vmNotifier.setLoading(true);

                      bool success = await vm.createAccount();

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
                  : const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: vm.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== Response message ====================
              if (vm.errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: vm.isSuccessMessage
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  child: Text(
                    vm.errorMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // ==================== MOBILE NUMBER ====================
              buildLabel("Mobile Number"),
              buildTextField(
                controller: vm.mobileController,
                hint: "09XXXXXXXXX",
                maxLength: 11,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                errorText: vm.mobileError,
                onChanged: (_) =>
                    vmNotifier.clearFieldError(vm.mobileController),
              ),
              const SizedBox(height: 15),

              // ==================== PIN ====================
              buildLabel("PIN"),
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
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // ==================== FIRST NAME ====================
              buildLabel("First Name"),
              buildTextField(
                controller: vm.firstNameController,
                hint: "Juan",
                errorText: vm.firstNameError,
                onChanged: (_) =>
                    vmNotifier.clearFieldError(vm.firstNameController),
              ),
              const SizedBox(height: 15),

              // ==================== MIDDLE NAME ====================
              buildLabel("Middle Name (Optional)"),
              buildTextField(
                controller: vm.middleNameController,
                hint: "Dela",
                errorText: vm.middleNameError,
                onChanged: (_) =>
                    vmNotifier.clearFieldError(vm.middleNameController),
              ),
              const SizedBox(height: 15),

              // ==================== LAST NAME ====================
              buildLabel("Last Name"),
              buildTextField(
                controller: vm.lastNameController,
                hint: "Cruz",
                errorText: vm.lastNameError,
                onChanged: (_) =>
                    vmNotifier.clearFieldError(vm.lastNameController),
              ),
              const SizedBox(height: 15),

              // ==================== SECURITY QUESTION ====================
              buildLabel("Security Question (for PIN reset)"),
              DropdownButtonFormField<String>(
                initialValue: vm.selectedQuestion,
                hint: const Text("Pili ug pangutana"),
                dropdownColor: Colors.white,
                decoration: inputDecorationWithError(vm.questionError),
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
              const SizedBox(height: 15),

              // ==================== SECURITY ANSWER ====================
              buildLabel("Tubag (Answer)"),
              buildTextField(
                controller: vm.answerController,
                hint: "Isulat ang imong tubag",
                errorText: vm.answerError,
                onChanged: (_) =>
                    vmNotifier.clearFieldError(vm.answerController),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HELPERS ====================
  Widget buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType ?? TextInputType.text,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14),
        errorText: errorText,
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  InputDecoration inputDecorationWithError(String? errorText) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      errorText: errorText,
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }
}
