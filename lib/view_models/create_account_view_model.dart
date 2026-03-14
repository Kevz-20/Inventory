import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/create_account_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/create_account_repository.dart';
import '../services/db_service.dart';
import '../services/supabase_service.dart';

final createAccountProvider =
    ChangeNotifierProvider.autoDispose<CreateAccountViewModel>((ref) {
      final dbService = DBService.instance;
      final repository = CreateAccountRepository(dbService);
      return CreateAccountViewModel(repository, const AuthRepository());
    });

class CreateAccountViewModel extends ChangeNotifier {
  final CreateAccountRepository _repository;
  final AuthRepository _authRepository;

  bool _disposed = false;

  CreateAccountViewModel(this._repository, this._authRepository) {
    loadSecurityQuestions();

    mobileController.addListener(() {
      if (mobileError != null) _validateMobile();
    });
    emailController.addListener(() {
      if (emailError != null) _validateEmail();
    });
    passwordController.addListener(() {
      if (passwordError != null || confirmPasswordError != null) {
        _validatePasswordFields();
      }
    });
    confirmPasswordController.addListener(() {
      if (confirmPasswordError != null) _validatePasswordFields();
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

  final formKey = GlobalKey<FormState>();

  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();
  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final answerController = TextEditingController();

  String? selectedQuestion;
  List<String> questions = [];

  bool isLoading = false;
  bool submitted = false;
  bool isLoadingQuestions = true;
  bool isSuccessMessage = false;

  bool get usesBackendAuth => SupabaseService.isConfigured;

  String? mobileError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  String? pinError;
  String? confirmPinError;
  String? firstNameError;
  String? middleNameError;
  String? lastNameError;
  String? answerError;
  String? questionError;
  String? errorMessage;

  @override
  void dispose() {
    _disposed = true;
    mobileController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
      if (!context.mounted) return false;
      showSnackBar(context, 'Mobile Number Already Exist');
      return false;
    }

    if (await _repository.isFullNameExists(firstName, middleName, lastName)) {
      if (!context.mounted) return false;
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

      if (usesBackendAuth) {
        await _authRepository.signUpWithEmail(
          email: emailController.text.trim(),
          password: passwordController.text,
          firstName: firstName,
          middleName: middleName,
          lastName: lastName,
          mobileNumber: mobile,
        );
      }

      await _repository.upsertLocalAccount(account);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mobileNumber', account.mobileNumber);
      if (usesBackendAuth) {
        await prefs.setString('lastLoginEmail', emailController.text.trim());
      }

      final fullNameParts = [
        account.firstName,
        if ((account.middleName ?? '').isNotEmpty) account.middleName!,
        account.lastName,
      ];
      await prefs.setString('fullName', fullNameParts.join(' '));

      clearFields();
      if (!context.mounted) return false;
      showSnackBar(context, 'Account created successfully!', success: true);
      return true;
    } catch (e) {
      final error = e.toString().toLowerCase();
      final isDuplicateMobile =
          error.contains('mobile number already exists') ||
          error.contains('mobile number already exist') ||
          (error.contains('unique constraint failed') &&
              error.contains('account.mobile_number'));

      if (!context.mounted) return false;
      showSnackBar(
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

  bool _validateForm() {
    _validateMobile();
    _validateEmail();
    _validatePasswordFields();
    _validatePin();
    _validateNameFields();
    _validateAnswer();
    _validateQuestion();

    final valid =
        mobileError == null &&
        emailError == null &&
        passwordError == null &&
        confirmPasswordError == null &&
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
    final mobile = mobileController.text.trim();

    if (mobile.isEmpty) {
      mobileError = 'Please enter mobile number';
    } else if (!RegExp(r'^09\d{9}$').hasMatch(mobile)) {
      mobileError = 'Mobile number must start with 09 and be 11 digits';
    } else {
      mobileError = null;
    }

    safeNotifyListeners();
  }

  void _validateEmail() {
    if (!usesBackendAuth) {
      emailError = null;
      safeNotifyListeners();
      return;
    }

    final email = emailController.text.trim();
    if (email.isEmpty) {
      emailError = 'Please enter email';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      emailError = 'Enter a valid email address';
    } else {
      emailError = null;
    }

    safeNotifyListeners();
  }

  void _validatePasswordFields() {
    if (!usesBackendAuth) {
      passwordError = null;
      confirmPasswordError = null;
      safeNotifyListeners();
      return;
    }

    if (passwordController.text.isEmpty) {
      passwordError = 'Please enter password';
    } else if (passwordController.text.length < 8) {
      passwordError = 'Password must be at least 8 characters';
    } else {
      passwordError = null;
    }

    if (confirmPasswordController.text.isEmpty) {
      confirmPasswordError = 'Please confirm password';
    } else if (passwordController.text != confirmPasswordController.text) {
      confirmPasswordError = 'Passwords do not match';
    } else {
      confirmPasswordError = null;
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
    final nameRegex = RegExp(r'^[a-zA-Z\s\.-]+$');

    if (firstNameController.text.isEmpty) {
      firstNameError = 'Please enter first name';
    } else if (!nameRegex.hasMatch(firstNameController.text)) {
      firstNameError = 'Only letters, spaces, hyphens, or dots allowed';
    } else {
      firstNameError = null;
    }

    if (middleNameController.text.isNotEmpty &&
        !nameRegex.hasMatch(middleNameController.text)) {
      middleNameError = 'Only letters, spaces, hyphens, or dots allowed';
    } else {
      middleNameError = null;
    }

    if (lastNameController.text.isEmpty) {
      lastNameError = 'Please enter last name';
    } else if (!nameRegex.hasMatch(lastNameController.text)) {
      lastNameError = 'Only letters, spaces, hyphens, or dots allowed';
    } else {
      lastNameError = null;
    }

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

  void setLoading(bool value) {
    isLoading = value;
    safeNotifyListeners();
  }

  void clearFieldError(TextEditingController controller) {
    if (controller == mobileController) mobileError = null;
    if (controller == emailController) emailError = null;
    if (controller == passwordController) passwordError = null;
    if (controller == confirmPasswordController) confirmPasswordError = null;
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

  void clearFields() {
    mobileController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    pinController.clear();
    confirmPinController.clear();
    firstNameController.clear();
    middleNameController.clear();
    lastNameController.clear();
    answerController.clear();
    selectedQuestion = null;

    mobileError = null;
    emailError = null;
    passwordError = null;
    confirmPasswordError = null;
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
