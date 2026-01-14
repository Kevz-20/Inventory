import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account_model.dart';
import '../repositories/account_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final Ref ref;
  final AccountRepository accountRepository;

  ProfileViewModel(this.ref, this.accountRepository);

  String? error;
  Account? account;
  bool isLoading = false;

  // Load account data
  Future<void> loadAccount() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      account = await accountRepository.getAccountDetails();
    } catch (e) {
      account = null;
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  // Reset account
  void reset() {
    account = null;
    error = null;
    isLoading = false;
    notifyListeners();
  }
  Future<bool> updateProfile(Account updated) async {
  try {
    await accountRepository.updateAccount(updated); // API / local save
    account = updated; // update local data
    notifyListeners();
    return true;
  } catch (e) {
    error = e.toString();
    notifyListeners();
    return false;
  }
}
}
