import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../../view_models/new_customer_view_model.dart';

class NewCustomerPage extends ConsumerWidget {
  const NewCustomerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(newCustomerViewModelProvider);
    final vmNotifier = ref.read(newCustomerViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Add New Customer'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField('First Name', vmNotifier.firstNameController),
            _buildTextField('Middle Name (optional)', vmNotifier.middleNameController),
            _buildTextField('Last Name', vmNotifier.lastNameController),
            _buildTextField('Contact Number', vmNotifier.contactController, keyboardType: TextInputType.number, inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,   // Only digits
                        LengthLimitingTextInputFormatter(11),    // Max 11 digits
                      ],),
            _buildTextField('Municipality', vmNotifier.municipalityController),
            _buildTextField('Barangay', vmNotifier.barangayController),
            _buildTextField('Landmark / Street', vmNotifier.landmarkController),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: vm.isLoading
                    ? null
                    : () async {
                        await vmNotifier.saveCustomer(context);
                        // ✅ No need to pop or reload here anymore
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: vm.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Customer',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
  String label,
  TextEditingController controller, {
  TextInputType keyboardType = TextInputType.text,
  List<TextInputFormatter>? inputFormatters, // add this
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters, // apply formatters here
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        fillColor: Colors.white,
        filled: true,
      ),
    ),
  );
}
}
