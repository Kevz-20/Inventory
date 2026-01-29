import 'package:dswd_slp/core/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../view_models/login_view_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(loginViewModelProvider).loadSavedMobile();
    });

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void triggerShake() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(loginViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    // Logo
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

                    // Mobile Number
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
                              color: Colors.grey.withAlpha(51),
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
                            const Icon(
                              Icons.swap_horiz,
                              color: AppColors.textPrimary,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // PIN
                    const Text(
                      "PIN",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        final pin = viewModel.pin;
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index < pin.length
                                      ? AppColors.primaryLight
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: Colors.black54,
                                    width: 2,
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 25),

                    // Keypad
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: 9,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1,
                                ),
                            itemBuilder: (context, index) {
                              final label = "${index + 1}";
                              return _buildKey(label);
                            },
                          ),
                          const SizedBox(height: 12),

                          // LAST ROW (0 + BACKSPACE)
                          GridView.count(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1,
                            children: [
                              Container(),

                              _buildKey("0"),

                              viewModel.pin.isNotEmpty
                                  ? _buildBackspaceKey()
                                  : Container(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom links
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

  // NUMBER KEY (unchanged)
  Widget _buildKey(String label) {
    final viewModel = ref.read(loginViewModelProvider);
    return GestureDetector(
      onTapDown: (_) => viewModel.setPressed(label.hashCode, true),
      onTapUp: (_) {
        viewModel.setPressed(label.hashCode, false);
        viewModel.onKeyTap(context, label, ref, onInvalid: triggerShake);
      },
      onTapCancel: () => viewModel.setPressed(label.hashCode, false),
      child: AnimatedScale(
        scale: viewModel.isPressed(label.hashCode) ? 0.85 : 1.0,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(51),
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // BACKSPACE KEY (same style as numbers)
  Widget _buildBackspaceKey() {
    final viewModel = ref.read(loginViewModelProvider);

    return GestureDetector(
      onTapDown: (_) => viewModel.setPressed(-1, true),
      onTapUp: (_) {
        viewModel.setPressed(-1, false);
        viewModel.onKeyTap(context, 'back', ref, onInvalid: triggerShake);
      },
      onTapCancel: () => viewModel.setPressed(-1, false),
      child: AnimatedScale(
        scale: viewModel.isPressed(-1) ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(51),
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(child: Icon(Icons.backspace_outlined, size: 26)),
        ),
      ),
    );
  }
}
