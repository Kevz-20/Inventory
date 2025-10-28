import 'package:flutter/material.dart';

class LoginViewModel extends ChangeNotifier {
  String _pin = "";
  String _mobileNumber = "0955555555";

  String get pin => _pin;
  String get mobileNumber => _mobileNumber;

  void onKeyTap(BuildContext context, String value) {
    if (value == "back") {
      if (_pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    } else if (value.toLowerCase() == "enter") {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (_pin.length < 4) {
      _pin += value;
    }
    notifyListeners();
  }

  void resetPin() {
    _pin = "";
    notifyListeners();
  }

  void changeMobileNumber(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _mobileNumber);

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Change Mobile Number"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  decoration: const InputDecoration(
                    labelText: "Enter new mobile number",
                    hintText: "09XXXXXXXXX",
                    counterText: "",
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "${controller.text.length}/11",
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  final newNumber = controller.text.trim();
                  final isValid =
                      RegExp(r'^[0-9]+$').hasMatch(newNumber) &&
                      newNumber.startsWith("09") &&
                      newNumber.length == 11;

                  if (isValid) {
                    _mobileNumber = newNumber;
                    Navigator.pop(context);
                    notifyListeners();
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Invalid Number"),
                        content: const Text(
                          "Please enter a valid mobile number starting with 09 and containing exactly 11 digits.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: const Text("Save"),
              ),
            ],
          ),
        );
      },
    );
  }
}
