import 'package:flutter/material.dart';

class CreateAccountViewModel extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  final mobileController = TextEditingController();
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();
  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final answerController = TextEditingController();

  bool isFormValid = false;
  String? selectedQuestion;

  final questions = [
    "Unsa imong paboritong pagkaon?",
    "Unsa ang ngalan sa imong inahan?",
    "Unsa imong paboritong lugar?",
    "Unsa imong first pet?",
  ];

  CreateAccountViewModel() {
    mobileController.addListener(validateForm);
    pinController.addListener(validateForm);
    confirmPinController.addListener(validateForm);
    firstNameController.addListener(validateForm);
    middleNameController.addListener(validateForm);
    lastNameController.addListener(validateForm);
    answerController.addListener(validateForm);
  }

  String? validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your mobile number';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Numbers only';
    if (!value.startsWith('09')) return 'Must start with 09';
    if (value.length != 11) return 'Must be 11 digits';
    return null;
  }

  void validateForm() {
    final valid =
        mobileController.text.isNotEmpty &&
        pinController.text.length == 4 &&
        confirmPinController.text == pinController.text &&
        firstNameController.text.isNotEmpty &&
        lastNameController.text.isNotEmpty &&
        selectedQuestion != null &&
        answerController.text.isNotEmpty &&
        validateMobile(mobileController.text) == null;

    if (isFormValid != valid) {
      isFormValid = valid;
      notifyListeners();
    }
  }

  void disposeControllers() {
    mobileController.dispose();
    pinController.dispose();
    confirmPinController.dispose();
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    answerController.dispose();
  }

  void clearFields() {
    mobileController.clear();
    pinController.clear();
    confirmPinController.clear();
    firstNameController.clear();
    middleNameController.clear();
    lastNameController.clear();
    answerController.clear();
    selectedQuestion = null;
    isFormValid = false;
    notifyListeners();
  }
}
