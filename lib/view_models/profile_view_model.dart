import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account_model.dart';
import '../providers/account_repository_provider.dart';
import '../repositories/account_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final Ref ref;
  AccountRepository? accountRepository;

  ProfileViewModel(this.ref);

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

  Future<void> loadAccount() async {
    if (accountRepository == null) return;

    try {
      account = await accountRepository!.getAccountDetails();
    } catch (e) {
      error = e.toString();
    }
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
