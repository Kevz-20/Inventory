import 'package:flutter/material.dart';
import '../models/change_pin_model.dart';
import '../repositories/change_pin_repository.dart';
import '../services/db_service.dart';

class ChangePinViewModel extends ChangeNotifier {
  final oldPinController = TextEditingController();
  final newPinController = TextEditingController();
  final confirmPinController = TextEditingController();
  final mobileController = TextEditingController(); // for first-time users

  late ChangePinRepository repository;
  int? accountId;
  bool loading = true;
  String? errorMessage;
  bool needMobileInput = false;

  ChangePinViewModel() {
    _init();
  }

  Future<void> _init() async {
    try {
      final db = await DBService.instance.database;
      repository = ChangePinRepository(db);

      accountId = await repository.getAccountId();
      if (accountId == null) {
        needMobileInput = true; // user must enter mobile
      }
    } catch (e) {
      errorMessage = e.toString();
      debugPrint("ChangePinViewModel init error: $e");
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> saveMobileAndLoadAccount() async {
    final mobile = mobileController.text.trim();
    if (mobile.length < 10) return "Enter a valid mobile number";

    try {
      await repository.saveMobileNumber(mobile);
      accountId = await repository.getAccountId();
      if (accountId == null) return "Account not found for this mobile number";
      needMobileInput = false;
      notifyListeners();
      return null;
    } catch (e) {
      return "Error saving mobile: $e";
    }
  }

  Future<String?> submit() async {
    if (accountId == null) return "Account ID missing";

    final model = ChangePinModel(
      oldPin: oldPinController.text.trim(),
      newPin: newPinController.text.trim(),
      confirmPin: confirmPinController.text.trim(),
    );

    if (!model.isValid()) return "All PINs must be 4 digits.";
    if (!model.doPinsMatch()) return "New PIN and confirm PIN must match.";
    if (!model.isNewPinDifferent()) {
      return "New PIN must be different from old PIN.";
    }

    final success = await repository.changePin(
      accountId!,
      model.oldPin,
      model.newPin,
    );
    return success ? null : "Old PIN is incorrect.";
  }
}
