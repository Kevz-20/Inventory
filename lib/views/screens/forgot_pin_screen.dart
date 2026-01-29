// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
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
  Widget _futuristicField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int? maxLength,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        maxLength: maxLength,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          counterText: "",
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45),
          prefixIcon: icon != null ? Icon(icon, color: Colors.green) : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.95),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.green.withOpacity(0.5), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.greenAccent.withOpacity(0.8), width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vmState = ref.watch(forgotPinViewModelProvider);

    ref.listen<ForgotPinViewModel>(forgotPinViewModelProvider, (_, state) {
      if (state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white, // entire background white
      appBar: const AppHeader(title: 'Forgot PIN', showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white, // card still white
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.green.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 0),
                    ),
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Recover Your PIN",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C2C2C),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Enter your registered mobile number",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 30),
                    _futuristicField(
                      controller: vmState.mobileController,
                      hint: "09XXXXXXXXX",
                      maxLength: 11,
                      keyboardType: TextInputType.number,
                      icon: Icons.phone_android,
                    ),
                    if (vmState.account != null) ...[
                      _futuristicField(
                        controller: vmState.newPinController,
                        hint: "New PIN",
                        maxLength: 4,
                        obscure: true,
                        keyboardType: TextInputType.number,
                        icon: Icons.lock_outline,
                      ),
                      FutureBuilder<String>(
                        future: vmState.securityQuestion,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              snapshot.data!,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                      _futuristicField(
                        controller: vmState.answerController,
                        hint: "Your Answer",
                        icon: Icons.help_outline,
                      ),
                    ],
                    const SizedBox(height: 35),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: vmState.isLoading
                            ? null
                            : () async {
                                if (vmState.account == null) {
                                  await vmState.fetchAccount();
                                } else if (vmState.validateAnswer()) {
                                  final success = await vmState.updatePin();
                                  if (success && context.mounted) {
                                    context.go('/login');
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 86, 137, 87),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: vmState.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "CONTINUE",
                                style: TextStyle(
                                  color: Color.fromARGB(255, 11, 11, 11),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
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
