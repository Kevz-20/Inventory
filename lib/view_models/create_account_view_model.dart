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

  // -------------------- Dispose Safety --------------------
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    // Dispose controllers
    mobileController.dispose();
    pinController.dispose();
    confirmPinController.dispose();
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    answerController.dispose();
    super.dispose();
  }

  void safeNotifyListeners() {
    if (!_disposed) notifyListeners();
  }

  // ========================================================
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
    safeNotifyListeners();
  }

  // ================== CREATE ACCOUNT ==================
  Future<bool> createAccount(BuildContext context) async {
    submitted = true;
    if (!_validateForm()) return false;

    final mobile = mobileController.text.trim();
    final firstName = firstNameController.text.trim();
    final middleName = middleNameController.text.trim().isEmpty
        ? null
        : middleNameController.text.trim();
    final lastName = lastNameController.text.trim();

    if (await _repository.isPhoneNumberExists(mobile)) {
      // ignore: use_build_context_synchronously
      showSnackBar(context, 'Mobile Number Already Exist');
      return false;
    }

    if (await _repository.isFullNameExists(firstName, middleName, lastName)) {
      // ignore: use_build_context_synchronously
      showSnackBar(context, 'Full Name Already Exist');
      return false;
    }

    setLoading(true);

    try {
      final account = Account(
        mobileNumber: mobile,
        pin: pinController.text.trim(),
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        securityQuestionId: selectedQuestion != null
            ? questions.indexOf(selectedQuestion!) + 1
            : null,
        securityAnswer: answerController.text.trim(),
      );

      await _repository.createAccount(account);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mobileNumber', account.mobileNumber);
      final fullNameParts = [
        account.firstName,
        if ((account.middleName ?? '').isNotEmpty) account.middleName!,
        account.lastName,
      ];
      await prefs.setString('fullName', fullNameParts.join(' '));

      clearFields();
      // ignore: use_build_context_synchronously
      showSnackBar(context, "Account created successfully!", success: true);
      return true;
    } catch (e) {
      final error = e.toString().toLowerCase();
      final isDuplicateMobile =
          error.contains('mobile number already exists') ||
          error.contains('mobile number already exist') ||
          (error.contains('unique constraint failed') &&
              error.contains('account.mobile_number'));

      showSnackBar(
        // ignore: use_build_context_synchronously
        context,
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
        lastNameError == null &&
        answerError == null &&
        questionError == null;

    safeNotifyListeners();
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
    safeNotifyListeners();
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
    safeNotifyListeners();
  }

  void _validateNameFields() {
    firstNameError = firstNameController.text.isEmpty
        ? 'Please enter first name'
        : null;
    middleNameError = null;
    lastNameError = lastNameController.text.isEmpty
        ? 'Please enter last name'
        : null;
    safeNotifyListeners();
  }

  void _validateAnswer() {
    answerError = answerController.text.isEmpty
        ? 'Please enter your answer'
        : null;
    safeNotifyListeners();
  }

  void _validateQuestion() {
    questionError = (selectedQuestion == null || selectedQuestion!.isEmpty)
        ? 'Please select a question'
        : null;
    safeNotifyListeners();
  }

  // ================== HELPERS ==================
  void setLoading(bool value) {
    isLoading = value;
    safeNotifyListeners();
  }

  void clearFieldError(TextEditingController controller) {
    if (controller == mobileController) mobileError = null;
    if (controller == pinController) pinError = null;
    if (controller == confirmPinController) confirmPinError = null;
    if (controller == firstNameController) firstNameError = null;
    if (controller == middleNameController) middleNameError = null;
    if (controller == lastNameController) lastNameError = null;
    if (controller == answerController) answerError = null;
    safeNotifyListeners();
  }

  void showSnackBar(
    BuildContext context,
    String message, {
    bool success = false,
  }) {
    final color = success ? Colors.green : Colors.red;
    final icon = success ? Icons.check_circle_outline : Icons.error_outline;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void showResponseMessage(
    String message, {
    bool success = false,
    int durationSeconds = 3,
  }) {
    errorMessage = message;
    isSuccessMessage = success;
    safeNotifyListeners();

    Future.delayed(Duration(seconds: durationSeconds), () {
      if (_disposed) return;
      errorMessage = null;
      isSuccessMessage = false;
      safeNotifyListeners();
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
    safeNotifyListeners();
  }
}
