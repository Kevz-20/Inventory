import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../repositories/account_repository.dart';
import '../../repositories/slpa_member_repository.dart';
import '../../services/db_service.dart';
import '../../view_models/add_member_view_model.dart';
import '../widgets/header.dart';

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
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: widget.isFirstMember ? 'Create First Member' : 'Add Member',
        showBackButton: !widget.isFirstMember,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('First Name'),
            _field(
              controller: vm.firstNameController,
              hint: 'Kyle',
              errorText: vm.firstNameError,
              inputFormatters: [nameFormatter],
              onChanged: (_) => vm.clearFieldError(vm.firstNameController),
            ),
            _label('Middle Name (Optional)'),
            _field(
              controller: vm.middleNameController,
              hint: 'Dela',
              errorText: vm.middleNameError,
              inputFormatters: [nameFormatter],
              onChanged: (_) => vm.clearFieldError(vm.middleNameController),
            ),
            _label('Last Name'),
            _field(
              controller: vm.lastNameController,
              hint: 'Santos',
              errorText: vm.lastNameError,
              inputFormatters: [nameFormatter],
              onChanged: (_) => vm.clearFieldError(vm.lastNameController),
            ),
            _label('Member Mobile Number'),
            _field(
              controller: vm.mobileController,
              hint: '09XXXXXXXXX',
              maxLength: 11,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              errorText: vm.mobileError,
              onChanged: (_) => vm.clearFieldError(vm.mobileController),
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    errorText: vm.pinError,
                    onChanged: (_) => vm.clearFieldError(vm.pinController),
                    suffixIcon: IconButton(
                      icon: Icon(
                        pinVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => pinVisible = !pinVisible),
                    ),
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    errorText: vm.confirmPinError,
                    onChanged: (_) =>
                        vm.clearFieldError(vm.confirmPinController),
                    suffixIcon: IconButton(
                      icon: Icon(
                        confirmPinVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(
                        () => confirmPinVisible = !confirmPinVisible,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _label('Security Question'),
            DropdownButtonFormField<String>(
              initialValue: vm.selectedQuestion,
              decoration: _decoration(errorText: vm.questionError),
              items: vm.questions
                  .map(
                    (question) => DropdownMenuItem(
                      value: question,
                      child: Text(question),
                    ),
                  )
                  .toList(),
              onChanged: vm.setSelectedQuestion,
            ),
            const SizedBox(height: 16),
            _label('Security Answer'),
            _field(
              controller: vm.answerController,
              hint: 'Enter answer',
              errorText: vm.answerError,
              onChanged: (_) => vm.clearFieldError(vm.answerController),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      )
                    : Text(
                        widget.isFirstMember
                            ? 'Continue to Login'
                            : 'Save Member',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );

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
        decoration: _decoration(
          hint: hint,
          errorText: errorText,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  InputDecoration _decoration({
    String? hint,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      counterText: '',
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
