import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/current_mobile_number_provider.dart';
import '../repositories/login_repository.dart';
import '../services/db_service.dart';
import '../core/app_colors.dart';

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

  Future<void> saveMobileNumber(String number) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mobileNumber', number);
    mobileNumber = number;
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
    // Check if mobile number is empty
    if (mobileNumber.isEmpty) {
      errorMessage = 'Please enter your mobile number';
      _showMessageDialog(context, errorMessage!, success: false);
      return;
    }

    // Check if PIN is incomplete
    if (pin.length != 4) {
      errorMessage = 'Enter 4-digit PIN';
      notifyListeners();
      onInvalid?.call(); // shake the PIN row
      _showMessageDialog(context, errorMessage!, success: false);
      return;
    }

    // Attempt to fetch account
    final account = await _repository.getAccountByMobileNumber(mobileNumber);

    // Successful login
    if (account != null && account.pin == pin) {
      errorMessage = null;
      notifyListeners();

      await saveMobileNumber(account.mobileNumber);
      ref.read(currentMobileNumberProvider.notifier).state =
          account.mobileNumber;

      if (context.mounted) {
        _showMessageDialog(context, 'Login successful!', success: true);
        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {
          GoRouter.of(context).go('/home', extra: 'fromLogin');
          clearPin(); // Clear PIN after navigation
        }
      }
    }
    // Invalid PIN or account not found
    else {
      errorMessage = account == null ? 'Account not found' : 'Invalid PIN';
      clearPin(); // clear PIN immediately
      notifyListeners(); // rebuild the dots
      onInvalid?.call(); // shake PIN row
      if (context.mounted) {
        _showMessageDialog(context, errorMessage!, success: false);
      }
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

  Future<void> changeMobileNumber(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        String? dialogError;
        return StatefulBuilder(
          builder: (context, setState) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AlertDialog(
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
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
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
            ),
          ),
        );
      },
    );

    if (result != null) {
      await saveMobileNumber(result);
    }
  }
}
