// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../repositories/change_pin_repository.dart';

class ChangePinViewModel extends ChangeNotifier {
  final ChangePinRepository _repo = ChangePinRepository();

  final oldPinController = TextEditingController();
  final newPinController = TextEditingController();
  final mobileController = TextEditingController();
  final answerController = TextEditingController();

  bool isLoading = false;

  // toggle visibility
  bool showOldPin = false;
  bool showNewPin = false;

  void toggleOldPin() {
    showOldPin = !showOldPin;
    notifyListeners();
  }

  void toggleNewPin() {
    showNewPin = !showNewPin;
    notifyListeners();
  }

  Future<void> changePin(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      await _repo.changePin(
        mobile: mobileController.text,
        answer: answerController.text,
        oldPin: oldPinController.text,
        newPin: newPinController.text,
      );

      // Clear all inputs after success
      oldPinController.clear();
      newPinController.clear();
      mobileController.clear();
      answerController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN changed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
