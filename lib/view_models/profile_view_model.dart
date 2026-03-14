import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account_model.dart';
import '../providers/account_repository_provider.dart';
import '../repositories/account_repository.dart';
import '../providers/current_mobile_number_provider.dart';

class ProfileViewModel extends ChangeNotifier {
  final Ref ref;
  AccountRepository? accountRepository;

  ProfileViewModel(this.ref) {
  // Listen to mobile number changes
  ref.listen<String?>(currentMobileNumberProvider, (previous, next) {
    if (next != previous && next != null) {
      // Reload account when mobile number changes
      loadAccount();
    }
  });
}

  String? error;
  Account? account;
  bool isLoading = false;

  // Initialize the repository and load account
  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    try {
      accountRepository = await ref.watch(accountRepositoryProvider.future);
      await loadAccount();
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  /// Load account details and ensure the current mobile number is correct
  Future<void> loadAccount() async {
    if (accountRepository == null) return;

    isLoading = true;
    notifyListeners();

    try {
      // Fetch full account details
      final accountDetails = await accountRepository!.getAccountDetails();
      account = accountDetails;

      error = null;
    } catch (e) {
      error = e.toString();
      account = null;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile(Account updated) async {
    if (accountRepository == null) return false;

    try {
      await accountRepository!.updateAccount(updated);
      account = updated;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void reset() {
    account = null;
    error = null;
    isLoading = false;
    notifyListeners();
  }
}
