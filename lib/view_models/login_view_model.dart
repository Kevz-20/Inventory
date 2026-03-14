// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_colors.dart';
import '../models/create_account_model.dart' as create_account;
import '../providers/current_mobile_number_provider.dart';
import '../repositories/auth_repository.dart';
import '../repositories/login_repository.dart';
import '../services/db_service.dart';
import '../services/supabase_service.dart';

final loginViewModelProvider = ChangeNotifierProvider<LoginViewModel>((ref) {
  final repository = LoginRepository(DBService.instance);
  return LoginViewModel(repository, const AuthRepository());
});

class LoginViewModel extends ChangeNotifier {
  final LoginRepository _repository;
  final AuthRepository _authRepository;

  LoginViewModel(this._repository, this._authRepository) {
    loadSavedMobile();
  }

  final LocalAuthentication _auth = LocalAuthentication();
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool shakePin = false;
  String mobileNumber = '';
  String pin = '';
  String? errorMessage;

  bool get usesBackendAuth => SupabaseService.isConfigured;

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
    if (usesBackendAuth) {
      emailController.text = prefs.getString('lastLoginEmail') ?? '';
    }
    notifyListeners();
  }

  Future<void> saveMobileNumber(String number, {WidgetRef? ref}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mobileNumber', number);
    mobileNumber = number;

    if (ref != null) {
      ref.read(currentMobileNumberProvider.notifier).state = number;
    }

    notifyListeners();
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastLoginEmail', email);
  }

  Future<void> _saveSelectedOrganizationId(String? organizationId) async {
    if (organizationId == null || organizationId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedOrganizationId', organizationId);
  }

  Future<void> _cacheBackendIdentity({
    required String mobile,
    required String firstName,
    required String? middleName,
    required String lastName,
  }) async {
    final account = create_account.Account(
      mobileNumber: mobile,
      pin: pin.isEmpty ? '0000' : pin,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      securityQuestionId: null,
      securityAnswer: null,
    );

    await _repository.upsertLocalAccountCache(account);

    final fullNameParts = [
      firstName,
      if ((middleName ?? '').isNotEmpty) middleName!,
      lastName,
    ];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', fullNameParts.join(' '));
  }

  Future<void> loginWithBiometric(BuildContext context, WidgetRef ref) async {
    if (usesBackendAuth) {
      _showMessageDialog(
        context,
        'Biometric login stays disabled until backend login is completed on this device.',
        success: false,
      );
      return;
    }

    if (mobileNumber.isEmpty) {
      _showMessageDialog(
        context,
        'Please set your mobile number first',
        success: false,
      );
      return;
    }

    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!canCheckBiometrics || !isDeviceSupported) {
        _showMessageDialog(
          context,
          'Biometric not supported on this device',
          success: false,
        );
        return;
      }

      final availableBiometrics = await _auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        _showMessageDialog(
          context,
          'No fingerprints or face enrolled',
          success: false,
        );
        return;
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Scan fingerprint to login',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (!didAuthenticate) return;

      final account = await _repository.getAccountByMobileNumber(mobileNumber);
      if (account == null) {
        _showMessageDialog(context, 'Account not found', success: false);
        return;
      }

      await saveMobileNumber(account.mobileNumber, ref: ref);
      if (context.mounted) {
        _showMessageDialog(context, 'Login successful!', success: true);
        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {
          GoRouter.of(context).go('/home', extra: 'fromLogin');
          clearPin();
        }
      }
    } catch (e) {
      _showMessageDialog(context, 'Biometric error: $e', success: false);
    }
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
    if (usesBackendAuth) {
      await loginWithEmailPassword(context, ref);
      return;
    }

    if (mobileNumber.isEmpty) {
      _showMessageDialog(
        context,
        'Please enter your mobile number',
        success: false,
      );
      return;
    }

    if (pin.length != 4) {
      shakePin = true;
      notifyListeners();
      onInvalid?.call();
      _showMessageDialog(context, 'Enter 4-digit PIN', success: false);
      return;
    }

    final account = await _repository.getAccountByMobileNumber(mobileNumber);
    if (account != null && account.pin == pin) {
      shakePin = false;
      notifyListeners();
      await saveMobileNumber(account.mobileNumber, ref: ref);
      if (context.mounted) {
        _showMessageDialog(context, 'Login successful!', success: true);
        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {
          GoRouter.of(context).go('/home', extra: 'fromLogin');
          clearPin();
        }
      }
    } else {
      shakePin = true;
      notifyListeners();
      clearPin();
      onInvalid?.call();
      _showMessageDialog(
        context,
        account == null ? 'Account not found' : 'Invalid PIN',
        success: false,
      );
    }
  }

  Future<void> loginWithEmailPassword(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessageDialog(
        context,
        'Enter your email and password',
        success: false,
      );
      return;
    }

    try {
      await _authRepository.signInWithEmail(email: email, password: password);
      final session = await _authRepository.loadAuthenticatedSession();
      if (session == null) {
        _showMessageDialog(
          context,
          'Unable to load your backend profile',
          success: false,
        );
        return;
      }

      await _saveEmail(email);
      await saveMobileNumber(session.profile.mobileNumber ?? '', ref: ref);
      await _saveSelectedOrganizationId(
        session.memberships.isEmpty
            ? null
            : session.memberships.first.organizationId,
      );
      await _cacheBackendIdentity(
        mobile: session.profile.mobileNumber ?? '',
        firstName: session.profile.firstName,
        middleName: session.profile.middleName,
        lastName: session.profile.lastName,
      );

      if (!context.mounted) return;
      _showMessageDialog(context, 'Login successful!', success: true);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!context.mounted) return;
      GoRouter.of(context).go('/home', extra: 'fromLogin');
      clearPin();
    } catch (e) {
      if (!context.mounted) return;
      _showMessageDialog(context, 'Login failed: $e', success: false);
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

  Future<void> changeMobileNumber(
    BuildContext context, {
    WidgetRef? ref,
  }) async {
    if (usesBackendAuth) {
      _showMessageDialog(
        context,
        'Mobile number comes from your backend profile.',
        success: false,
      );
      return;
    }

    final controller = TextEditingController(text: mobileNumber);
    String? validationError;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            title: const Text(
              'Change Mobile Number',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter your new mobile number below:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLength: 11,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '09XXXXXXXXX',
                    counterText: '',
                    errorText: validationError,
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  final number = controller.text.trim();
                  if (number.length != 11 ||
                      !RegExp(r'^09\d{9}$').hasMatch(number)) {
                    setState(() {
                      validationError = 'Enter a valid 11-digit mobile number';
                    });
                    return;
                  }
                  Navigator.pop(context, number);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) await saveMobileNumber(result, ref: ref);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
