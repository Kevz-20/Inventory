import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../../view_models/new_customer_view_model.dart';
import '../widgets/header.dart';
import '../../models/region7_psgc_model.dart';

class NewCustomerPage extends ConsumerWidget {
  const NewCustomerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(newCustomerViewModelProvider);
    final vmNotifier = ref.read(newCustomerViewModelProvider);

    // Show snackbar safely
    if (vm.snackbarMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(vm.snackbarMessage!)));
        vmNotifier.snackbarMessage = null;
      });
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Add New Customer', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField('First Name', vmNotifier.firstNameController),
            _buildTextField(
              'Middle Name (optional)',
              vmNotifier.middleNameController,
            ),
            _buildTextField('Last Name', vmNotifier.lastNameController),
            _buildTextField(
              'Contact Number',
              vmNotifier.contactController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
            ),
            _buildCityDropdown(vm, vmNotifier),
            _buildBarangayDropdown(vm, vmNotifier),
            _buildTextField('Landmark / Street', vmNotifier.landmarkController),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: vm.isLoading
                    ? null
                    : () async {
                        final success = await vmNotifier.saveCustomer();
                        if (success) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (Navigator.of(context).mounted) {
                              Navigator.of(context).pop(true);
                            }
                          });
                        }
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
    List<TextInputFormatter>? inputFormatters,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          disabledBorder: border,
          errorBorder: border,
          focusedErrorBorder: border,
        ),
      ),
    );
  }

  Widget _buildCityDropdown(
    NewCustomerViewModel vm,
    NewCustomerViewModel notifier,
  ) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<CityModel>(
        initialValue: vm.selectedCity,
        dropdownColor: Colors.white,
        items: vm.cities
            .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
            .toList(),
        onChanged: (CityModel? c) {
          if (c != null) notifier.selectCity(c);
        },
        decoration: InputDecoration(
          labelText: 'Municipality',
          filled: true,
          fillColor: Colors.white,
          border: border,
          enabledBorder: border,
          focusedBorder: border,
        ),
      ),
    );
  }

  Widget _buildBarangayDropdown(
    NewCustomerViewModel vm,
    NewCustomerViewModel notifier,
  ) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<BarangayModel>(
        initialValue: vm.selectedBarangay,
        dropdownColor: Colors.white,
        items: vm.barangays
            .map((b) => DropdownMenuItem(value: b, child: Text(b.name)))
            .toList(),
        onChanged: (BarangayModel? b) {
          if (b != null) notifier.selectBarangay(b);
        },
        decoration: InputDecoration(
          labelText: 'Barangay',
          filled: true,
          fillColor: Colors.white,
          border: border,
          enabledBorder: border,
          focusedBorder: border,
        ),
      ),
    );
  }
}
