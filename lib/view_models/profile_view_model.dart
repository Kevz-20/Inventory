import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account_model.dart';
import '../providers/database_provider.dart';
import '../repositories/account_repository.dart';

// StateProvider to track mobile number changes
final mobileNumberProvider = StateProvider<String?>((ref) => null);

// ProfileViewModelProvider automatically reloads account when mobile number changes
final profileViewModelProvider = FutureProvider.autoDispose<ProfileViewModel>((
  ref,
) async {
  final db = await ref.watch(databaseProvider.future); // DB instance
  final repo = AccountRepository(db);

  // Watch mobileNumberProvider for changes
  final mobileNumber = ref.watch(mobileNumberProvider);
  debugPrint(
    '⭐ [ProfileViewModelProvider] mobileNumber changed: $mobileNumber',
  );

  final viewModel = ProfileViewModel(ref, repo);
  if (mobileNumber != null) {
    await viewModel.loadAccount();
  }
  return viewModel;
});

class ProfileViewModel {
  final Ref ref; // access to providers
  final AccountRepository accountRepository; // repository for account

  ProfileViewModel(this.ref, this.accountRepository) {
    debugPrint('⭐ [ProfileViewModel] Created');
  }

  Account? account; // fetched account
  bool isLoading = false;
  String? error;

  // Load account data from repository
  Future<void> loadAccount() async {
    isLoading = true;
    _notify();
    try {
      account = await accountRepository.getAccountDetails();
      debugPrint('⭐ [ProfileViewModel] Loaded account: ${account?.toMap()}');
      error = null;
    } catch (e) {
      debugPrint('⭐ [ProfileViewModel] Error loading account: $e');
      account = null;
      error = e.toString();
    }
    isLoading = false;
    _notify();
  }

  // Reset account
  void reset() {
    debugPrint('⭐ [ProfileViewModel] Resetting account');
    account = null;
    error = null;
    isLoading = false;
    _notify();
  }

  // Notify UI
  void _notify() {
    ref.read(profileStateProvider.notifier).state++;
  }
}

// Simple StateProvider to trigger UI rebuilds
final profileStateProvider = StateProvider<int>((ref) => 0);
