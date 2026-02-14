import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../repositories/create_account_repository.dart';
import '../models/create_account_model.dart';
import '../services/db_service.dart';

final createAccountProvider =
    ChangeNotifierProvider.autoDispose<CreateAccountViewModel>((ref) {
      final dbService = DBService.instance;
      final repository = CreateAccountRepository(dbService);
      return CreateAccountViewModel(repository);
    });

class CreateAccountViewModel extends ChangeNotifier {
  final CreateAccountRepository _repository;

  CreateAccountViewModel(this._repository) {
    loadSecurityQuestions();

    // Real-time validation listeners
    mobileController.addListener(() {
      if (mobileError != null) _validateMobile();
    });
    pinController.addListener(() {
      if (pinError != null || confirmPinError != null) _validatePin();
    });
    confirmPinController.addListener(() {
      if (confirmPinError != null) _validatePin();
    });
    firstNameController.addListener(() {
      if (firstNameError != null) _validateNameFields();
    });
    middleNameController.addListener(() {
      if (middleNameError != null) _validateNameFields();
    });
    lastNameController.addListener(() {
      if (lastNameError != null) _validateNameFields();
    });
    answerController.addListener(() {
      if (answerError != null) _validateAnswer();
    });
  }

  // ================== CONTROLLERS ==================
  final formKey = GlobalKey<FormState>();

  final mobileController = TextEditingController();
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();

  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();

  final answerController = TextEditingController();

  // ================== DROPDOWN ==================
  String? selectedQuestion;
  List<String> questions = [];

  // ================== STATE ==================
  bool isLoading = false;
  bool submitted = false;
  bool isLoadingQuestions = true;
  bool isSuccessMessage = false;

  // ================== FIELD ERRORS ==================
  String? mobileError;
  String? pinError;
  String? confirmPinError;
  String? firstNameError;
  String? middleNameError;
  String? lastNameError;
  String? answerError;
  String? questionError;

  String? errorMessage;

  // ================== SECURITY QUESTIONS ==================
  Future<void> loadSecurityQuestions() async {
    setLoading(true);
    questions = await _repository.getSecurityQuestions();
    isLoadingQuestions = false;
    setLoading(false);
  }

  void setSelectedQuestion(String? value) {
    selectedQuestion = value;
    questionError = null;
    notifyListeners();
  }

  // ================== CREATE ACCOUNT ==================
  Future<bool> createAccount() async {
    submitted = true;
    if (!_validateForm()) return false;

    final mobile = mobileController.text.trim();

    if (await _repository.isPhoneNumberExists(mobile)) {
      showResponseMessage('Mobile Number Already Exist');
      return false;
    }

    setLoading(true);
    errorMessage = null;

    try {
      final account = Account(
        mobileNumber: mobile,
        pin: pinController.text.trim(),
        firstName: firstNameController.text.trim(),
        middleName: middleNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        securityQuestionId: selectedQuestion != null
            ? questions.indexOf(selectedQuestion!) + 1
            : null,
        securityAnswer: answerController.text.trim(),
      );

      await _repository.createAccount(account);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mobileNumber', account.mobileNumber);
      await prefs.setString(
        'fullName',
        '${account.firstName} ${account.middleName} ${account.lastName}',
      );

      clearFields();
      showResponseMessage("Account created successfully!", success: true);
      return true;
    } catch (e) {
      final error = e.toString().toLowerCase();
      final isDuplicateMobile =
          error.contains('mobile number already exists') ||
          error.contains('mobile number already exist') ||
          (error.contains('unique constraint failed') &&
              error.contains('account.mobile_number'));

      showResponseMessage(
        isDuplicateMobile
            ? 'Mobile Number Already Exist'
            : 'Failed to create account',
      );

      return false;
    } finally {
      setLoading(false);
    }
  }

  // ================== VALIDATION ==================
  bool _validateForm() {
    _validateMobile();
    _validatePin();
    _validateNameFields();
    _validateAnswer();
    _validateQuestion();

    bool valid =
        mobileError == null &&
        pinError == null &&
        confirmPinError == null &&
        firstNameError == null &&
        middleNameError == null &&
        lastNameError == null &&
        answerError == null &&
        questionError == null;

    notifyListeners();
    return valid;
  }

  void _validateMobile() {
    if (mobileController.text.isEmpty) {
      mobileError = 'Please enter mobile number';
    } else if (mobileController.text.length != 11 ||
        !RegExp(r'^[0-9]+$').hasMatch(mobileController.text)) {
      mobileError = 'Invalid mobile number format';
    } else {
      mobileError = null;
    }
    notifyListeners();
  }

  void _validatePin() {
    if (pinController.text.isEmpty) {
      pinError = 'Please enter PIN';
    } else if (pinController.text.length != 4 ||
        !RegExp(r'^[0-9]+$').hasMatch(pinController.text)) {
      pinError = 'PIN must be 4 digits';
    } else {
      pinError = null;
    }

    if (confirmPinController.text.isEmpty) {
      confirmPinError = 'Please confirm PIN';
    } else if (pinController.text != confirmPinController.text) {
      confirmPinError = 'PINs do not match';
    } else {
      confirmPinError = null;
    }
    notifyListeners();
  }

  void _validateNameFields() {
    firstNameError = firstNameController.text.isEmpty
        ? 'Please enter first name'
        : null;
    middleNameError = middleNameController.text.isEmpty
        ? 'Please enter middle name'
        : null;
    lastNameError = lastNameController.text.isEmpty
        ? 'Please enter last name'
        : null;
    notifyListeners();
  }

  void _validateAnswer() {
    answerError = answerController.text.isEmpty
        ? 'Please enter your answer'
        : null;
    notifyListeners();
  }

  void _validateQuestion() {
    questionError = (selectedQuestion == null || selectedQuestion!.isEmpty)
        ? 'Please select a question'
        : null;
    notifyListeners();
  }

  // ================== HELPERS ==================
  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void clearFieldError(TextEditingController controller) {
    if (controller == mobileController) mobileError = null;
    if (controller == pinController) pinError = null;
    if (controller == confirmPinController) confirmPinError = null;
    if (controller == firstNameController) firstNameError = null;
    if (controller == middleNameController) middleNameError = null;
    if (controller == lastNameController) lastNameError = null;
    if (controller == answerController) answerError = null;
    notifyListeners();
  }

  void showResponseMessage(
    String message, {
    bool success = false,
    int durationSeconds = 3,
  }) {
    errorMessage = message;
    isSuccessMessage = success;
    notifyListeners();

    Future.delayed(Duration(seconds: durationSeconds), () {
      errorMessage = null;
      isSuccessMessage = false;
      notifyListeners();
    });
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

    mobileError = null;
    pinError = null;
    confirmPinError = null;
    firstNameError = null;
    middleNameError = null;
    lastNameError = null;
    answerError = null;
    questionError = null;
    errorMessage = null;
    isSuccessMessage = false;

    formKey.currentState?.reset();
    notifyListeners();
  }
}
