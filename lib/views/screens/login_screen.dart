import 'package:dswd_slp/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      final vm = ref.read(loginViewModelProvider);
      vm.loadSavedMobile();
      vm.clearPin(); // ✅ Reset PIN when page loads
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

  void triggerShake() => _shakeController.forward(from: 0);

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(loginViewModelProvider);
    final size = MediaQuery.of(context).size;
    final scale = size.width > 600 ? 1.2 : 1.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallHeight = constraints.maxHeight < 600;

            final mainContent = ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// LOGO
                  Image.asset('lib/assets/logo.png', height: 80 * scale),
                  const SizedBox(height: 10),
                  Text(
                    "E.M.P.O.W.E.R",
                    style: TextStyle(
                      fontSize: 20 * scale,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// MOBILE NUMBER
                  GestureDetector(
                    onTap: () => viewModel.changeMobileNumber(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(40),
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Mobile Number: ",
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            viewModel.mobileNumber.isNotEmpty
                                ? viewModel.mobileNumber
                                : 'Not set',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.swap_horiz),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  /// PIN INDICATOR
                  const Text(
                    "PIN",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    // ignore: unnecessary_underscores
                    builder: (_, __) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (i) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 18 * scale,
                              height: 18 * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i < viewModel.pin.length
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

                  /// KEYPAD
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 9,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                              ),
                          itemBuilder: (_, i) => _buildKey("${i + 1}", scale),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          children: [
                            const SizedBox(),
                            _buildKey("0", scale),
                            viewModel.pin.isNotEmpty
                                ? _buildBackspaceKey(scale)
                                : const SizedBox(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );

            final bottomLinks = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      ref.read(loginViewModelProvider).clearPin(); // ✅ Reset PIN before leaving
                      context.push('/create_account');
                    },
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
                      onTap: () {
                        ref.read(loginViewModelProvider).clearPin(); // ✅ Clear PIN before leaving
                        context.push('/forgot_pin');
                      },
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
            );

            if (isSmallHeight) {
              // On small screens: everything scrolls together
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(children: [mainContent, bottomLinks]),
              );
            }

            // Normal screens: links pinned to bottom
            return Column(
              children: [
                Expanded(child: Center(child: mainContent)),
                bottomLinks,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildKey(String label, double scale) {
    final vm = ref.read(loginViewModelProvider);
    return GestureDetector(
      onTapDown: (_) => vm.setPressed(label.hashCode, true),
      onTapUp: (_) {
        vm.setPressed(label.hashCode, false);
        vm.onKeyTap(context, label, ref, onInvalid: triggerShake);
      },
      onTapCancel: () => vm.setPressed(label.hashCode, false),
      child: AnimatedScale(
        scale: vm.isPressed(label.hashCode) ? 0.85 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(40),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 22 * scale,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey(double scale) {
    final vm = ref.read(loginViewModelProvider);
    return GestureDetector(
      onTapDown: (_) => vm.setPressed(-1, true),
      onTapUp: (_) {
        vm.setPressed(-1, false);
        vm.onKeyTap(context, 'back', ref, onInvalid: triggerShake);
      },
      onTapCancel: () => vm.setPressed(-1, false),
      child: AnimatedScale(
        scale: vm.isPressed(-1) ? 0.85 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(40),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(Icons.backspace_outlined, size: 26 * scale),
        ),
      ),
    );
  }
}
