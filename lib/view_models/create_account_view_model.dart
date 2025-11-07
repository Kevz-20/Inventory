import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

final createAccountProvider =
    ChangeNotifierProvider.autoDispose<CreateAccountViewModel>((ref) {
      return CreateAccountViewModel();
    });

class CreateAccountViewModel extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  final mobileController = TextEditingController();
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();
  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final answerController = TextEditingController();

  String? selectedQuestion;
  List<String> questions = [
    "What is your pet's name?",
    "What is your favorite color?",
    "What is your mother's maiden name?",
  ];

  bool isFormValid = false;

  void validateForm() {
    isFormValid =
        formKey.currentState?.validate() == true &&
        selectedQuestion != null &&
        selectedQuestion!.isNotEmpty;
    notifyListeners();
  }

  String? validateMobile(String? value) {
    if (value == null || value.isEmpty) return 'Mobile number required';
    if (value.length != 11) return 'Mobile number must be 11 digits';
    return null;
  }
}
