import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../view_models/create_account_view_model.dart';
import '../widgets/dashboard_background.dart';

class CreateAccountScreen extends ConsumerWidget {
  const CreateAccountScreen({super.key});

  static const Color _pageBg = Color(0xFFF5F7FF);
  static const Color _cardBg = Colors.white;
  static const Color _cardBorder = Color(0xFFDDE5F8);
  static const Color _textPrimary = Color(0xFF213A6B);
  static const Color _textSecondary = Color(0xFF60739B);
  static const Color _accentBlue = Color(0xFF2F6BFF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(createAccountProvider);
    final notifier = ref.read(createAccountProvider.notifier);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    final slpaNameFormatter = FilteringTextInputFormatter.allow(
      RegExp(r'[a-zA-Z0-9\s\.\,&/\-\(\)]'),
    );

    return Scaffold(
      backgroundColor: _pageBg,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: _pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Image.asset(
            'lib/assets/arrowleft.png',
            width: 22,
            height: 22,
            fit: BoxFit.contain,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
        title: const Text(
          'Setup Association',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Stack(
        children: [
          const DashboardBackground(),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _heroCard(),
                      const SizedBox(height: 16),
                      _formCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Association / SLPA Name'),
                            TextField(
                              controller: vm.slpaNameController,
                              inputFormatters: [slpaNameFormatter],
                              onChanged: (_) => notifier.clearFieldError(
                                vm.slpaNameController,
                              ),
                              style: const TextStyle(
                                color: _textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: _decoration(
                                hint: 'Sample SLPA Association',
                                errorText: vm.slpaNameError,
                                icon: Icons.groups_rounded,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FBFF),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _cardBorder),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: _accentBlue.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      color: _accentBlue,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Set up the association first. Member accounts can be added in the next step.',
                                      style: TextStyle(
                                        color: _textSecondary,
                                        fontWeight: FontWeight.w600,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPadding),
                child: Material(
                  elevation: 14,
                  borderRadius: BorderRadius.circular(20),
                  shadowColor: const Color(
                    0xFF8EA1D1,
                  ).withValues(alpha: 0.22),
                  child: SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vm.isLoading
                            ? const Color(0xFFD8E1F5)
                            : _accentBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      onPressed: vm.isLoading
                          ? null
                          : () async {
                              final accountId = await notifier.createAccount(
                                context,
                              );
                              if (accountId == null || !context.mounted) return;
                              notifier.clearFields();
                              context.go(
                                '/add_member',
                                extra: {
                                  'accountId': accountId,
                                  'isFirstMember': true,
                                },
                              );
                            },
                      child: vm.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF173D86),
            Color(0xFF1D79D8),
            Color(0xFF28C4D5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4A9A).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Association Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Create the SLPA record first before adding members.',
                  style: TextStyle(
                    color: Color(0xFFE8F2FF),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8EA1D1).withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: _textPrimary,
        ),
      ),
    );
  }

  InputDecoration _decoration({
    String? hint,
    String? errorText,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      filled: true,
      fillColor: const Color(0xFFF9FBFF),
      prefixIcon: icon == null ? null : Icon(icon),
      prefixIconColor: _accentBlue,
      hintStyle: const TextStyle(
        color: _textSecondary,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _accentBlue, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red, width: 1.6),
      ),
    );
  }
}
