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

  // ─── Brand colours ────────────────────────────────────────────────────────
  static const Color _navy = Color(0xFF1B3A7A);
  static const Color _blue = Color(0xFF2D5BE3);
  static const Color _blueSoft = Color(0xFFEEF2FF);
  static const Color _blueMid = Color(0xFF204C93);
  static const Color _textSub = Color(0xFF5B6D96);
  static const Color _divider = Color(0xFFCDD5EE);

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(loginViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFECF1FF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8EEFF),
              Color(0xFFF2F5FF),
              Color(0xFFF5F8FF),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              final isTablet = width >= 700;
              final contentMaxWidth = isTablet ? 520.0 : 420.0;
              final contentWidth = math.min(width, contentMaxWidth);

              final horizontalPadding = isTablet ? 32.0 : 24.0;

              final veryShort = height < 650;
              final short = height < 730;

              // ── Sizing ──────────────────────────────────────────────────
              final logoCircle = veryShort
                  ? 68.0
                  : short
                  ? 82.0
                  : isTablet
                  ? 110.0
                  : 96.0;
              final logoHeight = logoCircle * 0.68;

              final titleSize = veryShort
                  ? 19.0
                  : short
                  ? 21.0
                  : isTablet
                  ? 27.0
                  : 24.0;
              final subtitleSize = veryShort ? 11.0 : 13.0;

              // Larger mobile font benefits 40-55 users
              final mobileLabelSize = veryShort ? 11.5 : 13.0;
              final mobileValueSize = veryShort ? 14.5 : 16.5;

              // "Enter your PIN" label
              final pinLabelSize = veryShort ? 15.5 : 18.0;
              final pinDotSize = veryShort ? 15.0 : 21.0;

              final gap1 = veryShort ? 6.0 : 10.0;
              final gap2 = veryShort ? 14.0 : 22.0;
              final gap3 = veryShort ? 10.0 : 14.0;

              final keypadSpacing = veryShort ? 10.0 : 14.0;

              final reservedHeight =
                  logoCircle +
                  gap1 +
                  titleSize +
                  subtitleSize +
                  gap2 +
                  68 + // mobile card
                  gap2 +
                  pinLabelSize +
                  gap3 +
                  pinDotSize +
                  gap2 +
                  52; // bottom links

              final remainingHeight = height - reservedHeight - 48;

              final widthBasedKeySize =
                  ((contentWidth -
                              (horizontalPadding * 2) -
                              (keypadSpacing * 2)) /
                          3)
                      .clamp(62.0, isTablet ? 110.0 : 94.0);

              final heightBasedKeySize =
                  ((remainingHeight - (keypadSpacing * 3)) / 4)
                      .clamp(52.0, 94.0);

              final keySize = math.min(widthBasedKeySize, heightBasedKeySize);
              // Larger ratio → bigger numbers → easier for 40-55 users
              final keyFontSize = keySize * 0.37;
              final backspaceIconSize = keySize * 0.37;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: veryShort ? 8 : 16,
                    ),
                    child: Column(
                      children: [
                        // ── Main content ──────────────────────────────────
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ── Logo in a glowing circle ──────────────
                                Container(
                                  width: logoCircle,
                                  height: logoCircle,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _blue.withOpacity(0.18),
                                        blurRadius: 28,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 8),
                                      ),
                                      BoxShadow(
                                        color: _blue.withOpacity(0.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'lib/assets/logo.png',
                                      height: logoHeight,
                                    ),
                                  ),
                                ),

                                SizedBox(height: gap1 + 4),

                                // ── Brand name ────────────────────────────
                                Text(
                                  'EMPOWER',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                    color: _navy,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Sari-Sari Store Manager',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: subtitleSize,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.4,
                                    color: _textSub,
                                  ),
                                ),

                                SizedBox(height: gap2),

                                // ── Mobile number card ────────────────────
                                GestureDetector(
                                  onTap: () => viewModel.changeMobileNumber(
                                    context,
                                    ref: ref,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: veryShort ? 11 : 13,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: const Color(0xFFDDE4F8),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _navy.withOpacity(0.07),
                                          blurRadius: 16,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Phone icon badge
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: _blueSoft,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.phone_android_rounded,
                                            color: _blue,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Label + value
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Mobile Number',
                                                style: TextStyle(
                                                  fontSize: mobileLabelSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: _textSub,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                viewModel.mobileNumber.isNotEmpty
                                                    ? viewModel.mobileNumber
                                                    : 'Not set — tap to add',
                                                style: TextStyle(
                                                  fontSize: mobileValueSize,
                                                  fontWeight: FontWeight.w800,
                                                  color: _navy,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Edit badge
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: _blueSoft,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.edit_outlined,
                                            color: _blue,
                                            size: 17,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: gap2),

                                // ── PIN section ───────────────────────────
                                Text(
                                  'Enter your PIN',
                                  style: TextStyle(
                                    fontSize: pinLabelSize,
                                    fontWeight: FontWeight.w700,
                                    color: _navy,
                                  ),
                                ),
                                SizedBox(height: gap3),

                                // PIN dots with shake + glow animation
                                AnimatedBuilder(
                                  animation: _shakeAnimation,
                                  builder: (_, _) {
                                    return Transform.translate(
                                      offset:
                                          Offset(_shakeAnimation.value, 0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(4, (i) {
                                          final filled =
                                              i < viewModel.pin.length;
                                          return AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 160),
                                            curve: Curves.easeOut,
                                            margin: EdgeInsets.symmetric(
                                              horizontal:
                                                  veryShort ? 8 : 11,
                                            ),
                                            width: pinDotSize,
                                            height: pinDotSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: filled
                                                  ? _blue
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color: filled
                                                    ? _blue
                                                    : const Color(
                                                        0xFFABBAD8),
                                                width: 2,
                                              ),
                                              boxShadow: filled
                                                  ? [
                                                      BoxShadow(
                                                        color: _blue
                                                            .withOpacity(
                                                                0.38),
                                                        blurRadius: 10,
                                                        spreadRadius: 1,
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                          );
                                        }),
                                      ),
                                    );
                                  },
                                ),

                                SizedBox(height: gap2),

                                // ── Keypad ────────────────────────────────
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

                        // ── Bottom links ──────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(loginViewModelProvider)
                                        .clearPin();
                                    context.push('/create_account');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.person_add_outlined,
                                          size: 16,
                                          color: _blueMid,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Bag-ong Account',
                                          style: TextStyle(
                                            fontSize: veryShort ? 12.0 : 13.5,
                                            color: _blueMid,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 18,
                                color: _divider,
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(loginViewModelProvider)
                                        .clearPin();
                                    context.push('/forgot_pin');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.lock_reset_outlined,
                                          size: 16,
                                          color: _blueMid,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Nakalimot sa PIN?',
                                          style: TextStyle(
                                            fontSize: veryShort ? 12.0 : 13.5,
                                            color: _blueMid,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
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

    const keypad = [
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
        scale: vm.isPressed(label.hashCode) ? 0.86 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE2E8F8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7A8AB5).withOpacity(0.16),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.80),
                blurRadius: 2,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
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
        scale: vm.isPressed(-1) ? 0.86 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE2E8F8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7A8AB5).withOpacity(0.16),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: iconSize,
              color: _navy,
            ),
          ),
        ),
      ),
    );
  }
}
