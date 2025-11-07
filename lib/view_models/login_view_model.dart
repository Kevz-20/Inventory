import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final loginViewModelProvider = ChangeNotifierProvider((_) => LoginViewModel());

class LoginViewModel extends ChangeNotifier {
  String mobileNumber = '09XXXXXXXXX';
  String pin = '';

  void changeMobileNumber(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change mobile number tapped')),
    );
  }

  void onKeyTap(BuildContext context, String label) {
    if (label == 'back') {
      if (pin.isNotEmpty) {
        pin = pin.substring(0, pin.length - 1);
        notifyListeners();
      }
    } else if (label == 'enter') {
      if (pin.length == 4) {
        GoRouter.of(context).go('/home');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Incomplete PIN')));
      }
    } else {
      if (pin.length < 4) {
        pin += label;
        notifyListeners();
      }
    }
  }
}
