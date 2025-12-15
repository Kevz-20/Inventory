import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../view_models/change_pin_view_model.dart';
import '../../core/app_colors.dart';
import '../widgets/header.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  late ChangePinViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = ChangePinViewModel();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        // Loading screen
        if (vm.loading) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Error screen
        if (vm.errorMessage != null) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Text(
                "Error: ${vm.errorMessage}",
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        // Ask mobile number first when not saved
        if (vm.needMobileInput) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const AppHeader(
              title: "Enter Mobile Number",
              showBackButton: true,
            ),
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: vm.mobileController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    decoration: const InputDecoration(
                      labelText: "Mobile Number",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final error = await vm.saveMobileAndLoadAccount();
                        if (error != null) _toast(error, false);
                      },
                      child: const Text(
                        "Save Mobile",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Main Change PIN screen
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: const AppHeader(title: "Change PIN", showBackButton: true),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _pinField(vm.oldPinController, "Old PIN"),
                const SizedBox(height: 16),
                _pinField(vm.newPinController, "New PIN"),
                const SizedBox(height: 16),
                _pinField(vm.confirmPinController, "Confirm PIN"),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final error = await vm.submit();
                      if (error == null) {
                        _toast("PIN successfully changed!", true);
                      } else {
                        _toast(error, false);
                      }
                    },
                    child: const Text(
                      "Save New PIN",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // PIN field with show/hide toggle
  Widget _pinField(TextEditingController controller, String label) {
    bool obscure = true;

    return StatefulBuilder(
      builder: (context, setState) {
        return TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            counterText: "",
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  obscure = !obscure;
                });
              },
            ),
          ),
        );
      },
    );
  }

  void _toast(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) Navigator.pop(context);
  }
}
