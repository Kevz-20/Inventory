import 'package:dswd_slp/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

final loginViewModelProvider = ChangeNotifierProvider((_) => LoginViewModel());

class LoginViewModel extends ChangeNotifier {
  String mobileNumber = ''; // saved mobile number
  String pin = ''; // current PIN input

  LoginViewModel() {
    _loadSavedMobile(); // load saved number on init
  }

  // Load mobile number from storage
  Future<void> _loadSavedMobile() async {
    final prefs = await SharedPreferences.getInstance();
    mobileNumber = prefs.getString('mobileNumber') ?? '';
    notifyListeners();
  }

  // Save mobile number to storage
  Future<void> saveMobileNumber(String number) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mobileNumber', number);
    mobileNumber = number;
    notifyListeners();
  }

  // Handle keypad tap
  void onKeyTap(BuildContext context, String label) {
    if (label == 'back') {
      if (pin.isNotEmpty) pin = pin.substring(0, pin.length - 1);
    } else if (label == 'enter') {
      if (pin.length == 4) {
        GoRouter.of(context).go('/home'); // navigate
        clearPin();
      }
    } else {
      if (pin.length < 4) pin += label; // append number
    }
    notifyListeners();
  }

  // Clear PIN input
  void clearPin() {
    pin = '';
    notifyListeners();
  }

  Future<void> changeMobileNumber(BuildContext context) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 10,
            backgroundColor: AppColors.surface,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            title: const Text(
              'Change Mobile Number',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Please enter your new mobile number below:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  decoration: InputDecoration(
                    hintText: 'e.g., 09123456789',
                    filled: true,
                    fillColor: Colors.grey[200],
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: errorMessage != null
                            ? AppColors.error
                            : AppColors.primaryLight,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {}); // update counter
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Error message centered
                    if (errorMessage != null)
                      Expanded(
                        child: Center(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    // Counter on the right
                    Text(
                      '${controller.text.length}/11',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newNumber = controller.text.trim();
                  if (newNumber.length == 11 &&
                      RegExp(r'^[0-9]+$').hasMatch(newNumber)) {
                    Navigator.of(context).pop(newNumber);
                  } else {
                    setState(() {
                      errorMessage = 'Invalid mobile number';
                    });
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
