import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_colors.dart';
import '../providers/current_mobile_number_provider.dart';
import '../repositories/login_repository.dart';
import '../services/db_service.dart';

final loginViewModelProvider = ChangeNotifierProvider<LoginViewModel>((ref) {
  final repository = LoginRepository(DBService.instance);
  return LoginViewModel(repository);
});

class LoginViewModel extends ChangeNotifier {
  final LoginRepository _repository;

  LoginViewModel(this._repository) {
    loadSavedMobile();
  }

  final formKey = GlobalKey<FormState>();

  bool shakePin = false;
  String mobileNumber = '';
  String pin = '';
  String? errorMessage;

  final Set<int> _pressedKeys = {};
  bool isPressed(int index) => _pressedKeys.contains(index);

  void setPressed(int index, bool pressed) {
    if (pressed) {
      _pressedKeys.add(index);
    } else {
      _pressedKeys.remove(index);
    }
    notifyListeners();
  }

  Future<void> loadSavedMobile() async {
    final prefs = await SharedPreferences.getInstance();
    mobileNumber = prefs.getString('mobileNumber') ?? '';
    notifyListeners();
  }

  Future<void> saveMobileNumber(String number, {WidgetRef? ref}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mobileNumber', number);
    mobileNumber = number;

    // ⚡ Update the current mobile number provider so other screens react
    if (ref != null) {
      ref.read(currentMobileNumberProvider.notifier).state = number;
    }

    notifyListeners();
  }

  void onKeyTap(
    BuildContext context,
    String label,
    WidgetRef ref, {
    VoidCallback? onInvalid,
  }) async {
    if (label == 'back') {
      if (pin.isNotEmpty) {
        pin = pin.substring(0, pin.length - 1);
        notifyListeners();
      }
    } else {
      if (pin.length < 4) {
        pin += label;
        notifyListeners();
      }

      if (pin.length == 4) {
        await login(context, ref, onInvalid: onInvalid);
      }
    }
  }

  void clearPin() {
    pin = '';
    notifyListeners();
  }

  Future<void> login(
    BuildContext context,
    WidgetRef ref, {
    VoidCallback? onInvalid,
  }) async {
    // No mobile number entered
    if (mobileNumber.isEmpty) {
      _showMessageDialog(
        context,
        'Please enter your mobile number',
        success: false,
      );
      return;
    }

    // PIN not complete
    if (pin.length != 4) {
      shakePin = true; // trigger red dots
      notifyListeners();
      onInvalid?.call();
      _showMessageDialog(context, 'Enter 4-digit PIN', success: false);
      return;
    }

    final account = await _repository.getAccountByMobileNumber(mobileNumber);

    if (account != null && account.pin == pin) {
      // Successful login
      shakePin = false; // reset error state
      notifyListeners();

      // ⚡ Save mobile number and update provider
      await saveMobileNumber(account.mobileNumber, ref: ref);

      if (context.mounted) {
        _showMessageDialog(context, 'Login successful!', success: true);
        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {
          GoRouter.of(context).go('/home', extra: 'fromLogin');
          clearPin(); // Clear PIN after navigation
        }
      }
    } else {
      // Invalid PIN or account not found
      shakePin = true; // trigger red dots
      notifyListeners();
      clearPin();
      onInvalid?.call();
      _showMessageDialog(
        // ignore: use_build_context_synchronously
        context,
        account == null ? 'Account not found' : 'Invalid PIN',
        success: false,
      );
    }
  }

  void _showMessageDialog(
    BuildContext context,
    String message, {
    required bool success,
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
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> changeMobileNumber(BuildContext context, {WidgetRef? ref}) async {
  final controller = TextEditingController(text: mobileNumber);
  String? validationError;

  final result = await showDialog<String>(
    context: context,
    barrierDismissible: false, // User must tap Save or Cancel
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          title: const Text(
            "Change Mobile Number",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter your new mobile number below:",
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLength: 11,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "09XXXXXXXXX",
                  counterText: "",
                  errorText: validationError,
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(fontSize: 16, letterSpacing: 1),
                onChanged: (_) {
                  if (validationError != null) {
                    setState(() {
                      validationError = null;
                    });
                  }
                },
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                final number = controller.text.trim();
                if (number.length != 11 || !RegExp(r'^09\d{9}$').hasMatch(number)) {
                  setState(() {
                    validationError = "Enter a valid 11-digit mobile number";
                  });
                  return;
                }
                Navigator.pop(context, number);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    ),
  );

  if (result != null) await saveMobileNumber(result, ref: ref);
}

}
