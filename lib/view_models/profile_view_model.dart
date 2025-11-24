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

  Account? _cachedAccount;

  Account? get account => _cachedAccount ?? _account;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProfileViewModel() {
    debugPrint('[ProfileVM] Constructor called');
    _init();
  }

  Future<void> _init() async {
    debugPrint('[ProfileVM] _init() started');

    _isLoading = true;
    notifyListeners();

    try {
      final db = await DBService.instance.database;
      debugPrint('[ProfileVM] Database loaded');

      repository = AccountRepository(db);
      debugPrint('[ProfileVM] Repository initialized');

      await loadAccount();
    } catch (e) {
      debugPrint('[ProfileVM] ERROR in _init(): $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('[ProfileVM] _init() completed');
    }
  }

  Future<void> loadAccount() async {
    debugPrint('[ProfileVM] loadAccount() called');

    if (_cachedAccount != null) {
      debugPrint('[ProfileVM] Using cached account: ${_cachedAccount?.id}');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('[ProfileVM] Fetching account from repository...');
      _account = await repository.getAccountDetails();

      if (_account == null) {
        debugPrint('[ProfileVM] No account found.');
      } else {
        debugPrint('[ProfileVM] Account loaded: ${_account!.id}');
      }

      _cachedAccount = _account;
    } catch (e) {
      debugPrint('[ProfileVM] ERROR in loadAccount(): $e');
      _error = e.toString();
      _account = null;
      _cachedAccount = null;
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('[ProfileVM] loadAccount() completed');
    }
  }

  Future<void> refreshAccount() async {
    debugPrint('[ProfileVM] refreshAccount() called');

    _cachedAccount = null;
    debugPrint('[ProfileVM] Cache cleared');

    await loadAccount();
  }

  Future<void> setMobileNumber(String mobileNumber) async {
    debugPrint('[ProfileVM] setMobileNumber($mobileNumber)');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mobileNumber', mobileNumber);
    debugPrint('[ProfileVM] Mobile number saved to SharedPrefs');

    repository.cachedAccountId = null;
    repository.cachedMobileNumber = null;

    _cachedAccount = null;
    debugPrint('[ProfileVM] Repository cache cleared');

    await loadAccount();
  }

  Future<void> clearAccountCache() async {
    debugPrint('[ProfileVM] clearAccountCache() called');

    _account = null;
    _cachedAccount = null;
    _error = null;
    _isLoading = false;

    repository.cachedAccountId = null;
    repository.cachedMobileNumber = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mobileNumber');
    debugPrint('[ProfileVM] SharedPrefs mobileNumber removed');

    notifyListeners();
    debugPrint('[ProfileVM] Account cache cleared and listeners notified');
  }
}

final profileViewModelProvider = ChangeNotifierProvider<ProfileViewModel>((
  ref,
) {
  debugPrint('[ProfileVM] Provider created');
  return ProfileViewModel();
});
