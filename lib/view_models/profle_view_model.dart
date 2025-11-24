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

  // Cache to avoid repeated DB queries
  Account? _cachedAccount;

  // Getters
  Account? get account => _cachedAccount ?? _account;
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

  // Load account details from repository
  Future<void> loadAccount() async {
    // Return cached account if available
    if (_cachedAccount != null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _account = await repository.getAccountDetails();
      _cachedAccount = _account; // Cache account
    } catch (e) {
      _error = e.toString();
      _account = null;
      _cachedAccount = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Force refresh account data from DB
  Future<void> refreshAccount() async {
    _cachedAccount = null; // Clear cache
    await loadAccount();
  }

  // Set mobile number in SharedPreferences and reload
  Future<void> setMobileNumber(String mobileNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mobileNumber', mobileNumber);

    repository.cachedAccountId = null;
    repository.cachedMobileNumber = null;
    _cachedAccount = null;

    await loadAccount();
  }

  // Clear cached account data (logout)
  Future<void> clearAccountCache() async {
    _account = null;
    _cachedAccount = null;
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
final profileViewModelProvider = ChangeNotifierProvider<ProfileViewModel>((
  ref,
) {
  return ProfileViewModel();
});
