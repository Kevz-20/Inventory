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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Form(
          key: vm.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildLabel("Mobile Number"),
              buildTextField(
                controller: vm.mobileController,
                hint: "09XXXXXXXXX",
                validator: vm.validateMobile,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 11,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildLabel("4-digit PIN"),
                        buildTextField(
                          controller: vm.pinController,
                          hint: "Enter 4-digit PIN",
                          obscureText: true,
                          maxLength: 4,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildLabel("Confirm PIN"),
                        buildTextField(
                          controller: vm.confirmPinController,
                          hint: "Re-enter PIN",
                          obscureText: true,
                          maxLength: 4,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              buildLabel("First Name"),
              buildTextField(
                controller: vm.firstNameController,
                hint: "e.g., Juan",
              ),
              const SizedBox(height: 16),
              buildLabel("Middle Name"),
              buildTextField(
                controller: vm.middleNameController,
                hint: "(optional)",
              ),
              const SizedBox(height: 16),
              buildLabel("Last Name"),
              buildTextField(
                controller: vm.lastNameController,
                hint: "e.g., Dela Cruz",
              ),
              const SizedBox(height: 16),
              buildLabel("Security Question (for PIN reset)"),
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
                      .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                      .toList(),
                  onChanged: (value) {
                    vmNotifier.selectedQuestion = value;
                    vmNotifier.validateForm();
                  },
                ),
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
                    backgroundColor: vm.isFormValid
                        ? AppColors.primary
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: vm.isFormValid
                      ? () {
                          if (vm.formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account created successfully!'),
                              ),
                            );
                          }
                        }
                      : null,
                  child: const Text(
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: TextInputType.text,
      inputFormatters: inputFormatters,
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
      maxLength: maxLength,
      validator: validator,
      onChanged: (_) => validator?.call(controller.text),
    );
  }
}
