import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    if (mobileNumber.isEmpty) {
      _showMessageDialog(
        context,
        'Please enter your mobile number',
        success: false,
      );
      return;
    }

    if (pin.length != 4) {
      onInvalid?.call();
      _showMessageDialog(context, 'Enter 4-digit PIN', success: false);
      return;
    }

    final account = await _repository.getAccountByMobileNumber(mobileNumber);

    if (account != null && account.pin == pin) {
      await saveMobileNumber(account.mobileNumber);
      ref.read(currentMobileNumberProvider.notifier).state =
          account.mobileNumber;

      if (context.mounted) {
        _showMessageDialog(context, 'Login successful!', success: true);
        await Future.delayed(const Duration(milliseconds: 500));
        // ignore: use_build_context_synchronously
        GoRouter.of(context).go('/home');
        clearPin();
      }
    } else {
      clearPin();
      onInvalid?.call();
      // ignore: use_build_context_synchronously
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

  Future<void> changeMobileNumber(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Mobile Number"),
        content: TextField(
          controller: controller,
          maxLength: 11,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: "09XXXXXXXXX"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final number = controller.text.trim();
              if (number.length == 11) {
                Navigator.pop(context, number);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (result != null) await saveMobileNumber(result);
  }
}
