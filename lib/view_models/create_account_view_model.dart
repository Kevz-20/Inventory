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
    slpaNameController.dispose();
    super.dispose();
  }

  void safeNotifyListeners() {
    if (!_disposed) notifyListeners();
  }

  // ========================================================
  CreateAccountViewModel(this._repository) {
    slpaNameController.addListener(() {
      if (slpaNameError != null) _validateSlpaName();
    });
  }

  // ================== CONTROLLERS ==================
  final formKey = GlobalKey<FormState>();

  final slpaNameController = TextEditingController();

  // ================== STATE ==================
  bool isLoading = false;
  bool submitted = false;
  bool isSuccessMessage = false;

  // ================== FIELD ERRORS ==================
  String? slpaNameError;

  String? errorMessage;

  // ================== CREATE ACCOUNT ==================
  Future<int?> createAccount(BuildContext context) async {
    submitted = true;
    if (!_validateForm()) return null;

    final slpaName = slpaNameController.text.trim();

    if (await _repository.isSlpaNameExists(slpaName)) {
      // ignore: use_build_context_synchronously
      showSnackBar(context, 'SLPA Name Already Exists');
      return null;
    }

    setLoading(true);

    try {
      final generatedKey = DateTime.now().millisecondsSinceEpoch;
      final account = Account(
        slpaName: slpaName,
        mobileNumber: 'slpa_$generatedKey',
        pin: '0000',
        firstName: slpaName,
        middleName: null,
        lastName: '',
      );

      final accountId = await _repository.createAccount(account);
      showSnackBar(
        // ignore: use_build_context_synchronously
        context,
        'Association saved successfully!',
        success: true,
      );
      return accountId;
    } catch (e) {
      showSnackBar(
        // ignore: use_build_context_synchronously
        context,
        'Failed to save association',
      );
      return null;
    } finally {
      setLoading(false);
    }
  }

  // ================== VALIDATION ==================
  bool _validateForm() {
    _validateSlpaName();

    bool valid = slpaNameError == null;

    safeNotifyListeners();
    return valid;
  }

  void _validateSlpaName() {
    final value = slpaNameController.text.trim();
    final slpaRegex = RegExp(r'^[a-zA-Z0-9\s\.\,&/\-\(\)]+$');

    if (value.isEmpty) {
      slpaNameError = 'Please enter SLPA name';
    } else if (!slpaRegex.hasMatch(value)) {
      slpaNameError =
          'Only letters, numbers, spaces, and . , & / - ( ) are allowed';
    } else {
      slpaNameError = null;
    }

    safeNotifyListeners();
  }

  // ================== HELPERS ==================
  void setLoading(bool value) {
    isLoading = value;
    safeNotifyListeners();
  }

  void clearFieldError(TextEditingController controller) {
    if (controller == slpaNameController) slpaNameError = null;
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
    slpaNameController.clear();
    slpaNameError = null;
    errorMessage = null;
    isSuccessMessage = false;

    formKey.currentState?.reset();
    safeNotifyListeners();
  }
}
