// ignore_for_file: use_build_context_synchronously

import 'package:dswd_slp/core/app_colors.dart';
import 'package:flutter/material.dart';
import '../repositories/change_pin_repository.dart';

class ChangePinViewModel extends ChangeNotifier {
  final ChangePinRepository _repo = ChangePinRepository();

  final oldPinController = TextEditingController();
  final newPinController = TextEditingController();
  final mobileController = TextEditingController();
  final answerController = TextEditingController();

  bool isLoading = false;
  bool isPinChangedSuccessfully = false;
  String? errorMessage;

  Map<String, dynamic>? _account;
  bool isMobileVerified = false;
  bool isSecurityVerified = false;
  bool isOldPinVerified = false;

  // toggle visibility
  bool showOldPin = false;
  bool showNewPin = false;

  /// The security question the user chose during account creation.
  /// Available as soon as [verifyMobile] succeeds.
  /// Returns null if the mobile hasn't been verified yet.
  String? get userSecurityQuestion =>
      _account?['security_question'] as String?;

  void toggleOldPin() {
    showOldPin = !showOldPin;
    notifyListeners();
  }

  void toggleNewPin() {
    showNewPin = !showNewPin;
    notifyListeners();
  }

  Future<void> verifyMobile(BuildContext context) async {
    final mobile = mobileController.text.trim();
    if (mobile.length != 11 || !RegExp(r'^[0-9]+$').hasMatch(mobile)) {
      _showError(context, 'Invalid mobile number');
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      _account = await _repo.getAccountByMobile(mobile);
      isMobileVerified = true;
      isSecurityVerified = false;
      isOldPinVerified = false;
      answerController.clear();
      oldPinController.clear();
      newPinController.clear();
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      _showError(context, _friendlyError(e));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void verifySecurityAnswer(BuildContext context) {
    if (!isMobileVerified || _account == null) {
      _showError(context, 'Verify mobile number first');
      return;
    }

    final input = answerController.text.trim();
    final stored = (_account!['security_answer'] ?? '').toString().trim();

    if (input.isEmpty) {
      _showError(context, 'Please enter security answer');
      return;
    }

    if (stored.toLowerCase() != input.toLowerCase()) {
      _showError(context, 'Incorrect security answer');
      return;
    }

    isSecurityVerified = true;
    isOldPinVerified = false;
    oldPinController.clear();
    newPinController.clear();
    errorMessage = null;
    notifyListeners();
  }

  void verifyOldPin(BuildContext context) {
    if (!isSecurityVerified || _account == null) {
      _showError(context, 'Verify security answer first');
      return;
    }

    final input = oldPinController.text.trim();
    final stored = (_account!['pin'] ?? '').toString().trim();

    if (input.length != 4 || !RegExp(r'^[0-9]+$').hasMatch(input)) {
      _showError(context, 'Old PIN must be 4 digits');
      return;
    }

    if (input != stored) {
      _showError(context, 'Old PIN is incorrect');
      return;
    }

    isOldPinVerified = true;
    newPinController.clear();
    errorMessage = null;
    notifyListeners();
  }

  Future<void> saveNewPin(BuildContext context) async {
    if (!isOldPinVerified || _account == null) {
      _showError(context, 'Verify old PIN first');
      return;
    }

    final oldPin = oldPinController.text.trim();
    final newPin = newPinController.text.trim();

    if (newPin.length != 4 || !RegExp(r'^[0-9]+$').hasMatch(newPin)) {
      _showError(context, 'New PIN must be 4 digits');
      return;
    }
    if (newPin == oldPin) {
      _showError(context, 'New PIN must be different');
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      await _repo.updatePinById(
        memberId: _account!['id'] as int,
        newPin: newPin,
      );

      // Signal the screen to show snackbar and navigate.
      // Navigation stays in the widget tree where GoRouter context is valid.
      isPinChangedSuccessfully = true;
      notifyListeners();
    } catch (e) {
      _showError(context, _friendlyError(e));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearAll() {
    _account = null;
    isMobileVerified = false;
    isSecurityVerified = false;
    isOldPinVerified = false;
    isPinChangedSuccessfully = false;
    oldPinController.clear();
    newPinController.clear();
    mobileController.clear();
    answerController.clear();
    errorMessage = null;
    notifyListeners();
  }

  void _showError(BuildContext context, String message) {
    errorMessage = message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
    notifyListeners();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    return msg.startsWith('Exception: ')
        ? msg.replaceFirst('Exception: ', '')
        : msg;
  }

  @override
  void dispose() {
    oldPinController.dispose();
    newPinController.dispose();
    mobileController.dispose();
    answerController.dispose();
    super.dispose();
  }
}
