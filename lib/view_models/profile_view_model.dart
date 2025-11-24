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

  ProfileViewModel();

  Future<void> init() async {
    debugPrint('[ProfileVM] init() started');

    _isLoading = true;
    notifyListeners();

    try {
      final db = await DBService.instance.database;
      repository = AccountRepository(db);
      debugPrint('[ProfileVM] Repository initialized');

      await loadAccount();
    } catch (e) {
      debugPrint('[ProfileVM] ERROR in init(): $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('[ProfileVM] init() completed');
    }
  }

  Future<void> loadAccount() async {
    debugPrint('[ProfileVM] loadAccount() called');

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
    } catch (e) {
      debugPrint('[ProfileVM] ERROR in loadAccount(): $e');
      _error = e.toString();
      _account = null;
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('[ProfileVM] loadAccount() completed');
    }
  }

  Future<void> setMobileNumber(String mobileNumber) async {
    debugPrint('[ProfileVM] setMobileNumber($mobileNumber)');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mobileNumber', mobileNumber);
    debugPrint('[ProfileVM] Mobile number saved to SharedPrefs');

    _account = null;
    await loadAccount();
  }

  Future<void> clearAccountCache() async {
    debugPrint('[ProfileVM] clearAccountCache() called');

    _account = null;
    _error = null;
    _isLoading = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mobileNumber');
    debugPrint('[ProfileVM] SharedPrefs mobileNumber removed');

    notifyListeners();
    debugPrint('[ProfileVM] Account cleared and listeners notified');
  }
}

final profileViewModelProvider = ChangeNotifierProvider<ProfileViewModel>((
  ref,
) {
  final vm = ProfileViewModel();
  vm.init();
  return vm;
});
