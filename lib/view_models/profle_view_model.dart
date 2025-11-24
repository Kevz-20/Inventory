import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_model.dart';
import '../repositories/account_repository.dart';
import '../services/db_service.dart';

class ProfileViewModel extends ChangeNotifier {
  late final AccountRepository repository;

  Account? _account;
  bool _isLoading = false;
  String? _error;

  Account? get account => _account;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProfileViewModel() {
    _init();
  }

  // Initialize repository and load account
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DBService.instance.database;
      repository = AccountRepository(db);
      await loadAccount();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load account details
  Future<void> loadAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _account = await repository.getAccountDetails();
    } catch (e) {
      _error = e.toString();
      _account = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh account details
  Future<void> refreshAccount() async {
    await loadAccount();
  }

  // Set mobile number in SharedPreferences and reload account
  Future<void> setMobileNumber(String mobileNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mobileNumber', mobileNumber);
    repository.cachedAccountId = null;
    repository.cachedMobileNumber = null;
    await loadAccount();
  }

  // Clear cached account data (logout)
  Future<void> clearAccountCache() async {
    _account = null;
    _error = null;
    _isLoading = false;

    repository.cachedAccountId = null;
    repository.cachedMobileNumber = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mobileNumber');

    notifyListeners();
  }
}

/// ----------------------
/// Riverpod Provider
/// ----------------------

// ProfileViewModel provider
final profileViewModelProvider = ChangeNotifierProvider<ProfileViewModel>((
  ref,
) {
  return ProfileViewModel();
});
