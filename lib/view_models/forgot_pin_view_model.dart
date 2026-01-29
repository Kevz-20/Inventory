import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/forgot_pin_repository.dart';
import '../services/db_service.dart';
import '../models/forgot_pin_model.dart';
final forgotPinViewModelProvider =
    ChangeNotifierProvider.autoDispose<ForgotPinViewModel>((ref) {
  final vm = ForgotPinViewModel(ForgotPinRepositoryWrapper());

  ref.onDispose(vm.disposeVM);

  return vm;
});

class ForgotPinRepositoryWrapper {
  Future<ForgotPinModel?> getAccountByMobile(String mobileNumber) async {
    final db = await DBService.instance.database;
    final repo = ForgotPinRepository(db);
    return repo.getAccountByMobileNumber(mobileNumber);
  }

  Future<void> updatePin(String mobile, String pin) async {
    final db = await DBService.instance.database;
    final repo = ForgotPinRepository(db);
    await repo.updatePin(mobile, pin);
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

  ForgotPinModel? get account => _cachedAccount;

  Future<void> fetchAccount() async {
    final mobile = mobileController.text.trim();

    if (!_validateMobile(mobile)) return;

    _setLoading(true);

    try {
      if (_cachedAccount == null || _cachedAccount!.mobileNumber != mobile) {
        _cachedAccount = await _repository.getAccountByMobile(mobile);
      }

      if (_cachedAccount == null) {
        _setError("Mobile number not found");
      } else {
        errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      _setError("Something went wrong");
    }

    _setLoading(false);
  }

  bool validateAnswer() {
    if (_cachedAccount == null) {
      _setError("No account loaded");
      return false;
    }

    final answer = answerController.text.trim();
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

    if (!_validatePin(newPin)) return false;
    if (_cachedAccount == null) {
      _setError("No account loaded");
      return false;
    }

    _setLoading(true);

    try {
      await _repository.updatePin(_cachedAccount!.mobileNumber, newPin);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mobileNumber', _cachedAccount!.mobileNumber);

      _cachedAccount = ForgotPinModel(
        mobileNumber: _cachedAccount!.mobileNumber,
        securityQuestionId: _cachedAccount!.securityQuestionId,
        securityAnswer: _cachedAccount!.securityAnswer,
        pin: newPin,
      );

      errorMessage = null;

      _setLoading(false);

      mobileController.clear();
      answerController.clear();
      newPinController.clear();

      notifyListeners();

      return true;
    } catch (e) {
      _setError("Failed to update PIN");
      _setLoading(false);
      return false;
    }
  }

  Future<String> get securityQuestion async {
    if (_cachedAccount == null) return "";
    final db = await DBService.instance.database;
    final id = _cachedAccount!.securityQuestionId;
    final result = await db.query(
      'security_questions',
      columns: ['question'],
      where: 'id = ?',
      whereArgs: [id],
    );

    return result.isNotEmpty
        ? result.first['question'] as String
        : "Security Question";
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
    }
    if (mobile.length != 11 || !RegExp(r'^[0-9]+$').hasMatch(mobile)) {
      _setError("Invalid mobile number");
      return false;
    }
    return true;
  }

  bool _validatePin(String pin) {
    if (pin.isEmpty) {
      _setError("Please enter new PIN");
      return false;
    }
    if (pin.length != 4 || !RegExp(r'^[0-9]+$').hasMatch(pin)) {
      _setError("PIN must be 4 digits");
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
