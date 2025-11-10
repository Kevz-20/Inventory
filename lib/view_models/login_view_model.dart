import 'package:dswd_slp/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/login_repository.dart';
import '../services/db_service.dart';

final loginViewModelProvider =
    ChangeNotifierProvider.autoDispose<LoginViewModel>((ref) {
      final repository = LoginRepository(DBService.instance);
      return LoginViewModel(repository);
    });

class LoginViewModel extends ChangeNotifier {
  final LoginRepository _repository;

  LoginViewModel(this._repository);

  final formKey = GlobalKey<FormState>();

  String mobileNumber = ''; // saved mobile number
  String pin = ''; // current PIN input
  String? errorMessage; // login error message

  final Set<int> _pressedKeys = {}; // NEW: track pressed buttons
  bool isPressed(int index) => _pressedKeys.contains(index);
  void setPressed(int index, bool pressed) {
    if (pressed) {
      _pressedKeys.add(index);
    } else {
      _pressedKeys.remove(index);
    }
    notifyListeners();
  }

  // Load saved mobile from prefs
  Future<void> loadSavedMobile() async {
    final prefs = await SharedPreferences.getInstance();
    mobileNumber = prefs.getString('mobileNumber') ?? '';
    notifyListeners();
  }

  // Save mobile number locally
  Future<void> saveMobileNumber(String number) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mobileNumber', number);
    mobileNumber = number;
    notifyListeners();
  }

  // Keypad input handler
  void onKeyTap(BuildContext context, String label) {
    if (label == 'back') {
      if (pin.isNotEmpty) {
        pin = pin.substring(0, pin.length - 1);
      }
    } else if (label == 'enter') {
      if (pin.length == 4) {
        login(context);
      }
    } else {
      if (pin.length < 4) {
        pin += label;
      }
    }
    notifyListeners();
  }

  // Clear PIN
  void clearPin() {
    pin = '';
    notifyListeners();
  }

  // Login
  Future<void> login(BuildContext context) async {
    debugPrint('Login started');
    debugPrint('Mobile: $mobileNumber, PIN: $pin');

    if (mobileNumber.isEmpty || pin.length != 4) {
      errorMessage = 'Enter valid mobile number and PIN';
      debugPrint('Validation failed: $errorMessage');
      notifyListeners();
      return;
    }

    final account = await _repository.getAccountByMobileNumber(mobileNumber);
    debugPrint(
      'Fetched account: ${account?.mobileNumber}, PIN: ${account?.pin}',
    );

    if (account != null && account.pin == pin) {
      debugPrint('Login successful');
      errorMessage = null;
      clearPin();
      await saveMobileNumber(account.mobileNumber);
      debugPrint('Saved mobile number: ${account.mobileNumber}');
      if (context.mounted) GoRouter.of(context).go('/home');
    } else {
      errorMessage = 'Invalid mobile number or PIN';
      debugPrint('Login failed: $errorMessage');
      notifyListeners();
    }
  }

  // Change mobile number dialog
  Future<void> changeMobileNumber(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        String? dialogError;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: AppColors.surface,
            title: const Text(
              'Change Mobile Number',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter your new mobile number:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  decoration: InputDecoration(
                    hintText: '09XXXXXXXXX',
                    filled: true,
                    fillColor: Colors.grey[200],
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: dialogError != null
                            ? AppColors.error
                            : AppColors.primaryLight,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (dialogError != null)
                      Expanded(
                        child: Center(
                          child: Text(
                            dialogError!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    Text(
                      '${controller.text.length}/11',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final newNumber = controller.text.trim();
                  if (newNumber.length == 11 &&
                      RegExp(r'^[0-9]+$').hasMatch(newNumber)) {
                    Navigator.of(context).pop(newNumber);
                  } else {
                    setState(() => dialogError = 'Invalid mobile number');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) await saveMobileNumber(result);
  }
}
