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
    _initListeners();
  }

  final formKey = GlobalKey<FormState>();

  final associationNameController = TextEditingController();
  final mobileController = TextEditingController();
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();
  final answerController = TextEditingController();

  String? selectedQuestion;
  List<String> questions = [];
  bool isLoading = false;
  bool submitted = false;
  bool isFormValid = false;
  bool isLoadingQuestions = true;
  String? errorMessage;

  // Initialize listeners to auto-validate the form
  void _initListeners() {
    associationNameController.addListener(validateForm);
    mobileController.addListener(validateForm);
    pinController.addListener(validateForm);
    confirmPinController.addListener(validateForm);
    answerController.addListener(validateForm);
  }

  // Load security questions from DB
  Future<void> loadSecurityQuestions() async {
    setLoading(true); // Start loading while fetching questions
    questions = await _repository.getSecurityQuestions();
    isLoadingQuestions = false;
    setLoading(false); // Stop loading after fetching
  }

  // Set selected question
  void setSelectedQuestion(String? value) {
    selectedQuestion = value;
    validateForm();
  }

  // Real-time form validation
  void validateForm() {
    isFormValid =
        associationNameController.text.isNotEmpty &&
        mobileController.text.isNotEmpty &&
        pinController.text.isNotEmpty &&
        confirmPinController.text.isNotEmpty &&
        answerController.text.isNotEmpty &&
        selectedQuestion?.isNotEmpty == true;
    notifyListeners();
  }

  // Validate mobile number
  String? validateMobile(String? value) {
    if (value == null || value.isEmpty) return 'Mobile number required';
    if (value.length != 11) return 'Mobile number must be 11 digits';
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Only numbers are allowed';
    return null;
  }

  // Validate PIN format
  String? validatePin(String? value) {
    if (value == null || value.isEmpty) return 'PIN is required';
    if (value.length != 4) return 'PIN must be 4 digits';
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Only numbers are allowed';
    return null;
  }

  // Validate PIN match
  String? validatePinMatch(String? value) {
    final pinError = validatePin(value);
    if (pinError != null) return pinError;
    if (pinController.text != confirmPinController.text) {
      return 'PINs do not match';
    }
    return null;
  }

  // Create account in DB
  Future<bool> createAccount() async {
    submitted = true;
    validateForm();

    if (!isFormValid) return false;

    setLoading(true);
    errorMessage = null;

    try {
      final account = Account(
        associationName: associationNameController.text,
        phoneNumber: mobileController.text,
        pin: pinController.text,
        securityQuestionId: selectedQuestion != null
            ? questions.indexOf(selectedQuestion!) + 1
            : null,
        securityAnswer: answerController.text,
      );

      await _repository.createAccount(account);
      return true;
    } catch (e) {
      if (e.toString().contains('Phone number already exists')) {
        errorMessage = 'Phone number already exists for this association';
      } else {
        errorMessage = 'Failed to create account';
      }
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Set loading
  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // Clear all fields
  void clearFields() {
    associationNameController.clear();
    mobileController.clear();
    pinController.clear();
    confirmPinController.clear();
    answerController.clear();
    selectedQuestion = null;
    errorMessage = null;
    formKey.currentState?.reset();
    validateForm();
  }
}
