import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../view_models/create_account_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../core/app_colors.dart';
import '../widgets/header.dart';

class CreateAccountScreen extends ConsumerWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(createAccountProvider);
    final vmNotifier = ref.read(createAccountProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: "Bag-ong Account", showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: vm.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Response message
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

              // Association Name
              buildLabel("Association Name"),
              buildTextField(
                controller: vm.associationNameController,
                hint: "DSWD-SLP",
                errorText: vm.associationError,
                onChanged: (_) =>
                    vmNotifier.clearFieldError(vm.associationNameController),
              ),
              const SizedBox(height: 15),

              // Mobile Number
              buildLabel("Mobile Number"),
              buildTextField(
                controller: vm.mobileController,
                hint: "09XXXXXXXXX",
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 11,
                keyboardType: TextInputType.number,
                errorText: vm.mobileError,
                onChanged: (_) =>
                    vmNotifier.clearFieldError(vm.mobileController),
              ),
              const SizedBox(height: 5),

              // PIN and Confirm PIN
              buildLabel("PIN"),
              Row(
                children: [
                  Expanded(
                    child: buildTextField(
                      controller: vm.pinController,
                      hint: "Enter 4-digit PIN",
                      obscureText: true,
                      maxLength: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.number,
                      errorText: vm.pinError,
                      onChanged: (_) =>
                          vmNotifier.clearFieldError(vm.pinController),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildTextField(
                      controller: vm.confirmPinController,
                      hint: "Re-enter PIN",
                      obscureText: true,
                      maxLength: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.number,
                      errorText: vm.confirmPinError,
                      onChanged: (_) =>
                          vmNotifier.clearFieldError(vm.confirmPinController),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Security Question
              buildLabel("Security Question (for PIN reset)"),
              DropdownButtonFormField<String>(
                initialValue: vm.selectedQuestion,
                hint: const Text("Pili ug pangutana"),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  errorText: vm.questionError,
                  errorStyle: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
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
              const SizedBox(height: 15),

              // Answer
              buildLabel("Tubag (Answer)"),
              buildTextField(
                controller: vm.answerController,
                hint: "Isulat ang imong tubag",
                errorText: vm.answerError,
                onChanged: (_) =>
                    vmNotifier.clearFieldError(vm.answerController),
              ),
              const SizedBox(height: 25),

              // Create Account Button
              SizedBox(
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

                            // Delay for 3 seconds
                            await Future.delayed(const Duration(seconds: 3));

                            // Clear all fields
                            vm.clearFields();

                            // Update mobile number on login screen
                            final loginVM = ref.read(loginViewModelProvider);
                            await loginVM.loadSavedMobile();

                            if (!context.mounted) return;

                            // Navigate to login screen
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
            ],
          ),
        ),
      ),
    );
  }

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
      ),
    );
  }
}
