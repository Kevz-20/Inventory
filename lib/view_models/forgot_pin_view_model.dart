import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/forgot_pin_repository.dart';
import '../services/db_service.dart';
import '../models/forgot_pin_model.dart';

final forgotPinViewModelProvider = ChangeNotifierProvider<ForgotPinViewModel>((
  ref,
) {
  final repository = ForgotPinRepositoryWrapper();
  return ForgotPinViewModel(repository);
});

class ForgotPinRepositoryWrapper {
  Future<ForgotPinModel?> getAccountByMobile(String mobileNumber) async {
    final db = await DBService.instance.database;
    final repo = ForgotPinRepository(db);
    return repo.getAccountByMobileNumber(mobileNumber);
  }
}

class ForgotPinViewModel extends ChangeNotifier {
  final ForgotPinRepositoryWrapper _repository;

  ForgotPinViewModel(this._repository);

  final mobileController = TextEditingController();
  final answerController = TextEditingController();
  final newPinController = TextEditingController();

  ForgotPinModel? _cachedAccount;

  bool isLoading = false;
  String? errorMessage;

  String get mobileNumber => mobileController.text.trim();
  ForgotPinModel? get account => _cachedAccount;

  Future<void> fetchAccount() async {
    final mobile = mobileController.text.trim();
    if (!_validateMobile(mobile)) return;

    _setLoading(true);

    try {
      ForgotPinModel? acc = _cachedAccount;
      if (acc == null || acc.mobileNumber != mobile) {
        acc = await _repository.getAccountByMobile(mobile);
        _cachedAccount = acc;
      }

      if (acc == null) {
        _setError("Mobile number not found");
      } else {
        errorMessage = null;
      }
    } catch (e) {
      _setError(e.toString());
    }

    _setLoading(false);
  }

  bool validateAnswer() {
    final answer = answerController.text.trim();
    if (_cachedAccount == null) {
      _setError("No account loaded");
      return false;
    }
    if (answer.isEmpty) {
      _setError("Please enter your answer");
      return false;
    }
    if (answer != _cachedAccount!.securityAnswer) {
      _setError("Incorrect answer");
      return false;
    }
    return true;
  }

  Future<bool> updatePin() async {
    final newPin = newPinController.text.trim();

    if (newPin.isEmpty ||
        newPin.length != 4 ||
        !RegExp(r'^[0-9]+$').hasMatch(newPin)) {
      _setError("PIN must be 4 digits");
      return false;
    }

    if (_cachedAccount == null) {
      _setError("No account loaded");
      return false;
    }

    _setLoading(true);
    try {
      final db = await DBService.instance.database;
      final repo = ForgotPinRepository(db);
      await repo.updatePin(_cachedAccount!.mobileNumber, newPin);

      _cachedAccount = ForgotPinModel(
        mobileNumber: _cachedAccount!.mobileNumber,
        securityQuestionId: _cachedAccount!.securityQuestionId,
        securityAnswer: _cachedAccount!.securityAnswer,
        pin: newPin,
      );

      errorMessage = null;
      clear();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Failed to update PIN: $e");
      _setLoading(false);
      return false;
    }
  }

  void clear() {
    mobileController.clear();
    answerController.clear();
    newPinController.clear();
    _cachedAccount = null;
    errorMessage = null;
    notifyListeners();
  }

  bool _validateMobile(String mobile) {
    if (mobile.isEmpty) {
      _setError("Please enter mobile number");
      return false;
    } else if (mobile.length != 11 || !RegExp(r'^[0-9]+$').hasMatch(mobile)) {
      _setError("Invalid mobile number");
      return false;
    }
    return true;
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    errorMessage = message;
    notifyListeners();
  }

  void disposeVM() {
    mobileController.dispose();
    answerController.dispose();
    newPinController.dispose();
  }
}
