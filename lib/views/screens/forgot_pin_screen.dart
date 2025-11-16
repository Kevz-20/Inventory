import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../view_models/forgot_pin_view_model.dart';
import '../../core/app_colors.dart';
import '../widgets/header.dart';

class ForgotPinScreen extends ConsumerStatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  ConsumerState<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends ConsumerState<ForgotPinScreen> {
  late ForgotPinViewModel vm;

  @override
  void initState() {
    super.initState();
    // Initialize the view model
    vm = ref.read(forgotPinViewModelProvider);
  }

  @override
  void dispose() {
    // Dispose controllers inside the view model
    vm.disposeVM();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vmState = ref.watch(forgotPinViewModelProvider);

    ref.listen<ForgotPinViewModel>(forgotPinViewModelProvider, (_, state) {
      if (vmState.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vmState.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: "Nakalimot sa PIN?", showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 51),
                      blurRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "I-Recover Imuha PIN",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Enter your registered 11-digit mobile number to recover your PIN.",
                      style: TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      "Mobile Number",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: vmState.mobileController,
                      maxLength: 11,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: "09XXXXXXXXX",
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9F9F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primaryLight,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    if (vmState.account != null) ...[
                      const SizedBox(height: 20),
                      const Text(
                        "New PIN",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: vmState.newPinController,
                        obscureText: true,
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Enter new PIN",
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9F9F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primaryLight,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      Text(
                        "Answer Security Question (ID: ${vmState.account!.securityQuestionId})",
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: vmState.answerController,
                        decoration: InputDecoration(
                          hintText: "Your answer",
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9F9F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primaryLight,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: vmState.isLoading
                            ? null
                            : () async {
                                if (vmState.account == null) {
                                  await vmState.fetchAccount();
                                } else if (vmState.validateAnswer()) {
                                  final success = await vmState.updatePin();
                                  if (success) {
                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "PIN updated successfully",
                                        ),
                                        backgroundColor: AppColors.primaryLight,
                                      ),
                                    );

                                    await Future.delayed(
                                      const Duration(seconds: 3),
                                    );

                                    if (!context.mounted) return;
                                    context.go('/login');
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 6,
                        ),
                        child: vmState.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                vmState.account == null
                                    ? "Submit"
                                    : "Validate Answer",
                                style: const TextStyle(
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
            ],
          ),
        ),
      ),
    );
  }
}
