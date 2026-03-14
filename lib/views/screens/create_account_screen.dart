import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../view_models/create_account_view_model.dart';
import '../widgets/header.dart';

class CreateAccountScreen extends ConsumerWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(createAccountProvider);
    final notifier = ref.read(createAccountProvider.notifier);

    final slpaNameFormatter = FilteringTextInputFormatter.allow(
      RegExp(r'[a-zA-Z0-9\s\.\,&/\-\(\)]'),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'Setup Association',
        showBackButton: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: vm.isLoading ? Colors.grey : AppColors.primary,
              ),
              onPressed: vm.isLoading
                  ? null
                  : () async {
                      final accountId = await notifier.createAccount(context);
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
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    )
                  : const Text('Continue'),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Association Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set up the association first. Member accounts can be added in the next step.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            _label('Association / SLPA Name'),
            TextField(
              controller: vm.slpaNameController,
              inputFormatters: [slpaNameFormatter],
              onChanged: (_) => notifier.clearFieldError(vm.slpaNameController),
              decoration: _decoration(
                hint: 'Sample SLPA Association',
                errorText: vm.slpaNameError,
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

  InputDecoration _decoration({
    String? hint,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      filled: true,
      fillColor: Colors.white,
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
