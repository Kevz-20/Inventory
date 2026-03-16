// ignore_for_file: use_build_context_synchronously

import 'dart:math' as math;

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

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = ref.read(loginViewModelProvider);
      await vm.loadSavedMobile();
      vm.clearPin();

      if (vm.mobileNumber.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 300));
        try {
          await vm.loginWithBiometric(context, ref);
        } catch (_) {}
      }
    });
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

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final isTablet = width >= 700;
            final contentMaxWidth = isTablet ? 520.0 : 420.0;
            final contentWidth = math.min(width, contentMaxWidth);

            final horizontalPadding = isTablet ? 24.0 : 16.0;

            final veryShort = height < 650;
            final short = height < 730;

            final logoHeight = veryShort
                ? 50.0
                : short
                ? 62.0
                : isTablet
                ? 88.0
                : 78.0;

            final titleSize = veryShort
                ? 16.0
                : short
                ? 18.0
                : isTablet
                ? 23.0
                : 20.0;

            final mobileFontSize = veryShort ? 13.0 : 16.0;
            final pinLabelSize = veryShort ? 15.0 : 18.0;
            final pinDotSize = veryShort ? 12.0 : 18.0;

            final gap1 = veryShort ? 6.0 : 10.0;
            final gap2 = veryShort ? 12.0 : 20.0;
            final gap3 = veryShort ? 8.0 : 12.0;

            final keypadSpacing = veryShort ? 8.0 : 12.0;

            final reservedHeight =
                logoHeight +
                gap1 +
                titleSize +
                gap2 +
                54 +
                gap2 +
                pinLabelSize +
                gap3 +
                pinDotSize +
                gap2 +
                50;

            final remainingHeight = height - reservedHeight - 40;

            final widthBasedKeySize =
                ((contentWidth -
                            (horizontalPadding * 2) -
                            (keypadSpacing * 2)) /
                        3)
                    .clamp(58.0, isTablet ? 105.0 : 90.0);

            final heightBasedKeySize =
                ((remainingHeight - (keypadSpacing * 3)) / 4).clamp(48.0, 90.0);

            final keySize = math.min(widthBasedKeySize, heightBasedKeySize);
            final keyFontSize = keySize * 0.32;
            final backspaceIconSize = keySize * 0.34;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: veryShort ? 8 : 14,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'lib/assets/logo.png',
                                height: logoHeight,
                              ),
                              SizedBox(height: gap1),
                              Text(
                                "E.M.P.O.W.E.R",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              SizedBox(height: gap2),

                              GestureDetector(
                                onTap: () => viewModel.changeMobileNumber(
                                  context,
                                  ref: ref,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: veryShort ? 10 : 12,
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
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Mobile Number: ",
                                          style: TextStyle(
                                            fontSize: mobileFontSize,
                                          ),
                                        ),
                                        Text(
                                          viewModel.mobileNumber.isNotEmpty
                                              ? viewModel.mobileNumber
                                              : 'Not set',
                                          style: TextStyle(
                                            fontSize: mobileFontSize,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.swap_horiz),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: gap2),

                              Text(
                                "PIN",
                                style: TextStyle(
                                  fontSize: pinLabelSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: gap3),

                              AnimatedBuilder(
                                animation: _shakeAnimation,
                                builder: (_, _) {
                                  return Transform.translate(
                                    offset: Offset(_shakeAnimation.value, 0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(4, (i) {
                                        return Container(
                                          margin: EdgeInsets.symmetric(
                                            horizontal: veryShort ? 5 : 8,
                                          ),
                                          width: pinDotSize,
                                          height: pinDotSize,
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

                              SizedBox(height: gap2),

                              _buildKeypad(
                                keySize: keySize,
                                spacing: keypadSpacing,
                                fontSize: keyFontSize,
                                backspaceIconSize: backspaceIconSize,
                              ),
                            ],
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  ref.read(loginViewModelProvider).clearPin();
                                  context.push('/create_account');
                                },
                                child: Text(
                                  "BAG-ONG ACCOUNT",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: veryShort ? 11.5 : 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  ref.read(loginViewModelProvider).clearPin();
                                  context.push('/forgot_pin');
                                },
                                child: Text(
                                  "NAKALIMOT SA PIN?",
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: veryShort ? 11.5 : 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
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
          },
        ),
      ),
    );
  }

  Widget _buildKeypad({
    required double keySize,
    required double spacing,
    required double fontSize,
    required double backspaceIconSize,
  }) {
    return Column(
      children: [
        for (int row = 0; row < 4; row++) ...[
          if (row > 0) SizedBox(height: spacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int col = 0; col < 3; col++) ...[
                if (col > 0) SizedBox(width: spacing),
                _buildKeypadItem(
                  row: row,
                  col: col,
                  keySize: keySize,
                  fontSize: fontSize,
                  backspaceIconSize: backspaceIconSize,
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildKeypadItem({
    required int row,
    required int col,
    required double keySize,
    required double fontSize,
    required double backspaceIconSize,
  }) {
    final vm = ref.watch(loginViewModelProvider);

    final keypad = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];

    final value = keypad[row][col];

    if (value.isEmpty) {
      return SizedBox(width: keySize, height: keySize);
    }

    if (value == 'back' && vm.pin.isEmpty) {
      return SizedBox(width: keySize, height: keySize);
    }

    return SizedBox(
      width: keySize,
      height: keySize,
      child: value == 'back'
          ? _buildBackspaceKey(backspaceIconSize)
          : _buildKey(value, fontSize),
    );
  }

  Widget _buildKey(String label, double fontSize) {
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
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey(double iconSize) {
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
          child: Center(child: Icon(Icons.backspace_outlined, size: iconSize)),
        ),
      ),
    );
  }
}
