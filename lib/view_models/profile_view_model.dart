import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../repositories/account_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final AccountRepository accountRepository;

  ProfileViewModel(this.accountRepository) {
    loadAccount();
  }

  Account? account;
  bool isLoading = false;
  String? error;

  Future<void> loadAccount() async {
    isLoading = true;
    notifyListeners();

    try {
      account = await accountRepository.getAccountDetails();
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  void reset() {
    account = null;
    error = null;
    isLoading = false;
    notifyListeners();
  }
}
