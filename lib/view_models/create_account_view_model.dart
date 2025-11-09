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
    loadSecurityQuestions(); // Load questions from DB

    // Real-time validation for each field
    associationNameController.addListener(() {
      if (associationError != null) _validateAssociation();
    });
    mobileController.addListener(() {
      if (mobileError != null) _validateMobile();
    });
    pinController.addListener(() {
      if (pinError != null || confirmPinError != null) _validatePin();
    });
    confirmPinController.addListener(() {
      if (confirmPinError != null) _validatePin();
    });
    answerController.addListener(() {
      if (answerError != null) _validateAnswer();
    });
  }

  final formKey = GlobalKey<FormState>();

  // Controllers
  final associationNameController = TextEditingController();
  final mobileController = TextEditingController();
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();
  final answerController = TextEditingController();

  // Dropdown
  String? selectedQuestion;
  List<String> questions = [];

  bool isLoading = false; // Loading indicator
  bool submitted = false; // Form submitted flag
  bool isLoadingQuestions = true; // Questions loading flag

  // Field-specific errors
  String? associationError;
  String? mobileError;
  String? pinError;
  String? confirmPinError;
  String? answerError;
  String? questionError;
  String? errorMessage; // General error message

  // Load security questions
  Future<void> loadSecurityQuestions() async {
    setLoading(true);
    questions = await _repository.getSecurityQuestions();
    isLoadingQuestions = false;
    setLoading(false);
  }

  // Set dropdown value and clear error
  void setSelectedQuestion(String? value) {
    selectedQuestion = value;
    questionError = null;
    notifyListeners();
  }

  // Create account
  Future<bool> createAccount() async {
    submitted = true;
    if (!_validateForm()) return false; // Stop if validation fails

    setLoading(true);
    errorMessage = null;

    try {
      final account = Account(
        associationName: associationNameController.text,
        mobileNumber: mobileController.text,
        pin: pinController.text,
        securityQuestionId: selectedQuestion != null
            ? questions.indexOf(selectedQuestion!) + 1
            : null,
        securityAnswer: answerController.text,
      );

      await _repository.createAccount(account);
      clearFields(); // Reset form after success
      return true;
    } catch (e) {
      // Set error message for display
      errorMessage = e.toString().contains('Mobile number already exists')
          ? 'Mobile number already exists'
          : 'Failed to create account';
      notifyListeners();
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Validate all fields
  bool _validateForm() {
    _validateAssociation();
    _validateMobile();
    _validatePin();
    _validateAnswer();
    _validateQuestion();

    // Return true if all errors are null
    bool valid =
        associationError == null &&
        mobileError == null &&
        pinError == null &&
        confirmPinError == null &&
        answerError == null &&
        questionError == null;

    notifyListeners();
    return valid;
  }

  // Individual field validation
  void _validateAssociation() {
    associationError = associationNameController.text.isEmpty
        ? 'Please enter association name'
        : null;
    notifyListeners();
  }

  // Validate Mobile Number
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

  // Validate PIN and Confirm PIN
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

  // Validate Answer
  void _validateAnswer() {
    answerError = answerController.text.isEmpty
        ? 'Please enter your answer'
        : null;
    notifyListeners();
  }

  // Validate Security Question Selection
  void _validateQuestion() {
    questionError = (selectedQuestion == null || selectedQuestion!.isEmpty)
        ? 'Please select a question'
        : null;
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // Clear specific field error on user input
  void clearFieldError(TextEditingController controller) {
    if (controller == associationNameController) associationError = null;
    if (controller == mobileController) mobileError = null;
    if (controller == pinController) pinError = null;
    if (controller == confirmPinController) confirmPinError = null;
    if (controller == answerController) answerError = null;
    notifyListeners();
  }

  // Reset all fields and errors
  void clearFields() {
    associationNameController.clear();
    mobileController.clear();
    pinController.clear();
    confirmPinController.clear();
    answerController.clear();
    selectedQuestion = null;

    associationError = null;
    mobileError = null;
    pinError = null;
    confirmPinError = null;
    answerError = null;
    questionError = null;
    errorMessage = null;

    formKey.currentState?.reset();
    notifyListeners();
  }
}
