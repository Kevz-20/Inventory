import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../repositories/account_repository.dart';
import '../../repositories/slpa_member_repository.dart';
import '../../services/db_service.dart';
import '../../view_models/add_member_view_model.dart';
import '../widgets/dashboard_background.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({
    super.key,
    this.accountId,
    this.isFirstMember = false,
  });

  final int? accountId;
  final bool isFirstMember;

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  static const Color _pageBg = Color(0xFFF5F7FF);
  static const Color _cardBg = Colors.white;
  static const Color _cardBorder = Color(0xFFDDE5F8);
  static const Color _textPrimary = Color(0xFF213A6B);
  static const Color _textSecondary = Color(0xFF60739B);
  static const Color _accentBlue = Color(0xFF2F6BFF);

  bool pinVisible = false;
  bool confirmPinVisible = false;

  late final AddMemberViewModel vm;

  final nameFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\.-]'));

  @override
  void initState() {
    super.initState();
    vm = AddMemberViewModel(
      SlpaMemberRepository(DBService.instance, AccountRepository()),
      accountId: widget.accountId,
    )..loadSecurityQuestions();
    vm.addListener(_refresh);
  }

  @override
  void dispose() {
    vm.removeListener(_refresh);
    vm.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: _pageBg,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: _pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: widget.isFirstMember
            ? IconButton(
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
                    context.go('/create_account');
                  }
                },
              )
            : IconButton(
                icon: Image.asset(
                  'lib/assets/arrowleft.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                ),
                onPressed: () => context.pop(),
              ),
        title: Text(
          widget.isFirstMember ? 'Create First Member' : 'Add Member',
          style: const TextStyle(
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
                            _label('First Name'),
                            _field(
                              controller: vm.firstNameController,
                              hint: 'Kyle',
                              errorText: vm.firstNameError,
                              inputFormatters: [nameFormatter],
                              onChanged: (_) =>
                                  vm.clearFieldError(vm.firstNameController),
                              icon: Icons.person_outline_rounded,
                            ),
                            _label('Middle Name (Optional)'),
                            _field(
                              controller: vm.middleNameController,
                              hint: 'Dela',
                              errorText: vm.middleNameError,
                              inputFormatters: [nameFormatter],
                              onChanged: (_) =>
                                  vm.clearFieldError(vm.middleNameController),
                              icon: Icons.person_outline_rounded,
                            ),
                            _label('Last Name'),
                            _field(
                              controller: vm.lastNameController,
                              hint: 'Santos',
                              errorText: vm.lastNameError,
                              inputFormatters: [nameFormatter],
                              onChanged: (_) =>
                                  vm.clearFieldError(vm.lastNameController),
                              icon: Icons.badge_rounded,
                            ),
                            _label('Member Mobile Number'),
                            _field(
                              controller: vm.mobileController,
                              hint: '09XXXXXXXXX',
                              maxLength: 11,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              errorText: vm.mobileError,
                              onChanged: (_) =>
                                  vm.clearFieldError(vm.mobileController),
                              icon: Icons.phone_android_rounded,
                            ),
                            _label('PIN'),
                            Row(
                              children: [
                                Expanded(
                                  child: _field(
                                    controller: vm.pinController,
                                    hint: '4-digit PIN',
                                    obscureText: !pinVisible,
                                    maxLength: 4,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    errorText: vm.pinError,
                                    onChanged: (_) =>
                                        vm.clearFieldError(vm.pinController),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        pinVisible
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                      ),
                                      onPressed: () =>
                                          setState(() => pinVisible = !pinVisible),
                                    ),
                                    icon: Icons.lock_outline_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _field(
                                    controller: vm.confirmPinController,
                                    hint: 'Confirm PIN',
                                    obscureText: !confirmPinVisible,
                                    maxLength: 4,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    errorText: vm.confirmPinError,
                                    onChanged: (_) => vm.clearFieldError(
                                      vm.confirmPinController,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        confirmPinVisible
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                      ),
                                      onPressed: () => setState(
                                        () => confirmPinVisible = !confirmPinVisible,
                                      ),
                                    ),
                                    icon: Icons.verified_user_outlined,
                                  ),
                                ),
                              ],
                            ),
                            _label('Security Question'),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: DropdownButtonFormField<String>(
                                initialValue: vm.selectedQuestion,
                                decoration: _decoration(
                                  errorText: vm.questionError,
                                  icon: Icons.help_outline_rounded,
                                ),
                                dropdownColor: Colors.white,
                                items: vm.questions
                                    .map(
                                      (question) => DropdownMenuItem(
                                        value: question,
                                        child: Text(
                                          question,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: _textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: vm.setSelectedQuestion,
                              ),
                            ),
                            _label('Security Answer'),
                            _field(
                              controller: vm.answerController,
                              hint: 'Enter answer',
                              errorText: vm.answerError,
                              onChanged: (_) =>
                                  vm.clearFieldError(vm.answerController),
                              icon: Icons.edit_note_rounded,
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
                              final success = await vm.saveMember(context);
                              if (!success || !context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    widget.isFirstMember
                                        ? 'First member created successfully'
                                        : 'Member added successfully',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              if (widget.isFirstMember) {
                                context.go('/login');
                              } else {
                                context.pop();
                              }
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
                          : Text(
                              widget.isFirstMember
                                  ? 'Continue to Login'
                                  : 'Save Member',
                              style: const TextStyle(
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
              Icons.badge_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isFirstMember ? 'Create First Member' : 'Add Member',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isFirstMember
                      ? 'Set up the first member account to secure the association.'
                      : 'Create another member account with security details.',
                  style: const TextStyle(
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

  Widget _field({
    required TextEditingController controller,
    required String hint,
    String? errorText,
    bool obscureText = false,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: const TextStyle(
          color: _textPrimary,
          fontWeight: FontWeight.w800,
        ),
        decoration: _decoration(
          hint: hint,
          errorText: errorText,
          suffixIcon: suffixIcon,
          icon: icon,
        ),
      ),
    );
  }

  InputDecoration _decoration({
    String? hint,
    String? errorText,
    Widget? suffixIcon,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      counterText: '',
      filled: true,
      fillColor: const Color(0xFFF9FBFF),
      suffixIcon: suffixIcon,
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
