import 'package:dswd_slp/core/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../view_models/login_view_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(loginViewModelProvider).loadSavedMobile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(loginViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Column(
              children: [
                Image.asset('lib/assets/logo.png', height: 80),
                const SizedBox(height: 10),
                const Text(
                  "E.M.P.O.W.E.R",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => viewModel.changeMobileNumber(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 51),
                      blurRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Mobile Number: ",
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        viewModel.mobileNumber.isNotEmpty
                            ? viewModel.mobileNumber
                            : 'Not set',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => viewModel.changeMobileNumber(context),
                      child: const Icon(
                        Icons.swap_horiz,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "PIN",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Consumer(
              builder: (context, ref, _) {
                final pin = ref.watch(loginViewModelProvider).pin;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < pin.length
                            ? AppColors.primaryLight
                            : Colors.transparent,
                        border: Border.all(color: Colors.black54, width: 2),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 25),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    String label;
                    if (index < 9) {
                      label = "${index + 1}";
                    } else if (index == 9) {
                      label = "back";
                    } else if (index == 10) {
                      label = "0";
                    } else {
                      label = "enter";
                    }

                    IconData? icon;
                    Color textColor = Colors.black;
                    if (label == "back") {
                      icon = Icons.backspace_outlined;
                    } else if (label == "enter") {
                      textColor = AppColors.primaryLight;
                    }

                    return GestureDetector(
                      onTapDown: (_) => viewModel.setPressed(index, true),
                      onTapUp: (_) {
                        viewModel.setPressed(index, false);
                        viewModel.onKeyTap(context, label);
                      },
                      onTapCancel: () => viewModel.setPressed(index, false),
                      child: AnimatedScale(
                        scale: viewModel.isPressed(index) ? 0.85 : 1.0,
                        curve: Curves.easeOut,
                        duration: const Duration(milliseconds: 120),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 51),
                                blurRadius: 2,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: icon != null
                                ? Icon(icon, size: 26, color: Colors.black87)
                                : Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => GoRouter.of(context).push('/create_account'),
                    child: const Text(
                      "BAG-ONG ACCOUNT",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => GoRouter.of(context).push('/forgot_pin'),
                    child: const Text(
                      "NAKALIMOT SA PIN?",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
