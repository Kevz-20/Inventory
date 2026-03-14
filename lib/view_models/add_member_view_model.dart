import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/account_repository.dart';
import '../repositories/slpa_member_repository.dart';
import '../services/db_service.dart';

final addMemberProvider =
    ChangeNotifierProvider.autoDispose<AddMemberViewModel>((ref) {
  return AddMemberViewModel(
    SlpaMemberRepository(DBService.instance, AccountRepository()),
  )..loadSecurityQuestions();
});

class AddMemberViewModel extends ChangeNotifier {
  AddMemberViewModel(this._repository, {this.accountId});

  final SlpaMemberRepository _repository;
  final int? accountId;

  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final mobileController = TextEditingController();
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();
  final answerController = TextEditingController();

  bool isLoading = false;
  String? selectedQuestion;
  List<String> questions = [];

  String? firstNameError;
  String? middleNameError;
  String? lastNameError;
  String? mobileError;
  String? pinError;
  String? confirmPinError;
  String? answerError;
  String? questionError;

  Future<void> loadSecurityQuestions() async {
    questions = await _repository.getSecurityQuestions();
    notifyListeners();
  }

  Future<bool> saveMember(BuildContext context) async {
    _validateAll();
    if (!_isValid()) return false;

    final mobile = mobileController.text.trim();
    if (await _repository.isMobileNumberExists(mobile)) {
      mobileError = 'Mobile number already exists';
      notifyListeners();
      return false;
    }

    isLoading = true;
    notifyListeners();
    try {
      await _repository.addMember(
        accountId: accountId,
        firstName: firstNameController.text.trim(),
        middleName: middleNameController.text.trim().isEmpty
            ? null
            : middleNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        mobileNumber: mobile,
        pin: pinController.text.trim(),
        securityQuestionId: questions.indexOf(selectedQuestion!) + 1,
        securityAnswer: answerController.text.trim(),
      );
      return true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedQuestion(String? value) {
    selectedQuestion = value;
    questionError = null;
    notifyListeners();
  }

  void clearFieldError(TextEditingController controller) {
    if (controller == firstNameController) firstNameError = null;
    if (controller == middleNameController) middleNameError = null;
    if (controller == lastNameController) lastNameError = null;
    if (controller == mobileController) mobileError = null;
    if (controller == pinController) pinError = null;
    if (controller == confirmPinController) confirmPinError = null;
    if (controller == answerController) answerError = null;
    notifyListeners();
  }

  void _validateAll() {
    final nameRegex = RegExp(r'^[a-zA-Z\s\.-]+$');

    if (firstNameController.text.trim().isEmpty) {
      firstNameError = 'Enter first name';
    } else if (!nameRegex.hasMatch(firstNameController.text.trim())) {
      firstNameError = 'Invalid first name';
    } else {
      firstNameError = null;
    }

    if (middleNameController.text.trim().isNotEmpty &&
        !nameRegex.hasMatch(middleNameController.text.trim())) {
      middleNameError = 'Invalid middle name';
    } else {
      middleNameError = null;
    }

    if (lastNameController.text.trim().isEmpty) {
      lastNameError = 'Enter last name';
    } else if (!nameRegex.hasMatch(lastNameController.text.trim())) {
      lastNameError = 'Invalid last name';
    } else {
      lastNameError = null;
    }

    final mobile = mobileController.text.trim();
    if (mobile.isEmpty) {
      mobileError = 'Enter mobile number';
    } else if (!RegExp(r'^09\d{9}$').hasMatch(mobile)) {
      mobileError = 'Use 11-digit mobile starting with 09';
    } else {
      mobileError = null;
    }

    final pin = pinController.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      pinError = 'PIN must be 4 digits';
    } else {
      pinError = null;
    }

    if (confirmPinController.text.trim() != pin) {
      confirmPinError = 'PINs do not match';
    } else {
      confirmPinError = null;
    }

    answerError = answerController.text.trim().isEmpty ? 'Enter answer' : null;
    questionError = selectedQuestion == null ? 'Select a question' : null;
    notifyListeners();
  }

  bool _isValid() {
    return firstNameError == null &&
        middleNameError == null &&
        lastNameError == null &&
        mobileError == null &&
        pinError == null &&
        confirmPinError == null &&
        answerError == null &&
        questionError == null;
  }

  @override
  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    mobileController.dispose();
    pinController.dispose();
    confirmPinController.dispose();
    answerController.dispose();
    super.dispose();
  }
}
