import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../view_models/create_account_view_model.dart';
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
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildLabel("Association Name"),
              buildTextField(
                controller: vm.associationNameController,
                hint: "e.g., SLP",
              ),

              const SizedBox(height: 15),
              buildLabel("Mobile Number"),
              buildTextField(
                controller: vm.mobileController,
                hint: "09XXXXXXXXX",
                validator: vm.validateMobile,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 11,
                keyboardType: TextInputType.number,
              ),
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
                      validator: vm.validatePinMatch,
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
                      validator: vm.validatePinMatch,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),
              buildLabel("Security Question (for PIN reset)"),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade900),
                    ),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                      hint: const Text("Pili ug pangutana"),
                      initialValue: vm.selectedQuestion,
                      items: vm.questions
                          .map(
                            (q) => DropdownMenuItem(value: q, child: Text(q)),
                          )
                          .toList(),
                      onChanged: vmNotifier.setSelectedQuestion,
                      validator: (_) => null,
                    ),
                  ),
                  if (vm.submitted && vm.selectedQuestion == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        'Please select a question',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),
              buildLabel("Tubag (Answer)"),
              buildTextField(
                controller: vm.answerController,
                hint: "Isulat ang imong tubag",
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: vm.isFormValid && !vm.isLoading
                        ? AppColors.primary
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: vm.isFormValid && !vm.isLoading
                      ? () async {
                          vmNotifier.setLoading(true);
                          final success = await vm.createAccount();
                          vmNotifier.setLoading(false);

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Account created successfully!'
                                    : vm.errorMessage ??
                                          'Failed to create account',
                              ),
                            ),
                          );
                          if (success) vm.clearFields();
                        }
                      : null,
                  child: vm.isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        )
                      : const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 18,
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
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType ?? TextInputType.text,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}
