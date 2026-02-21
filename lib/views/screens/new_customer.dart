import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../models/region7_psgc_model.dart';
import '../../view_models/new_customer_view_model.dart';
import '../widgets/header.dart';

class NewCustomerPage extends ConsumerStatefulWidget {
  const NewCustomerPage({super.key});

  @override
  ConsumerState<NewCustomerPage> createState() => _NewCustomerPageState();
}

class _NewCustomerPageState extends ConsumerState<NewCustomerPage> {
  List<String> filteredCities = [];
  List<String> filteredBarangays = [];
  List<BarangayModel> currentBarangays = [];
  bool _showValidationErrors = false;

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(newCustomerViewModelProvider);
    final vmNotifier = ref.read(newCustomerViewModelProvider);

    if (vm.snackbarMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.snackbarMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        vmNotifier.snackbarMessage = null;
      });
    }

    final sortedCities = List<CityModel>.from(vm.cities)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final sortedBarangays = List<BarangayModel>.from(vm.barangays)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Add New Customer', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(
              'First Name',
              vmNotifier.firstNameController,
              isRequired: true,
            ),
            _buildTextField(
              'Middle Name (optional)',
              vmNotifier.middleNameController,
            ),
            _buildTextField(
              'Last Name',
              vmNotifier.lastNameController,
              isRequired: true,
            ),
            _buildTextField(
              'Contact Number',
              vmNotifier.contactController,
              isRequired: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
            ),
            _buildSearchField(
              label: 'Municipality',
              controller: vm.cityController,
              isRequired: true,
              items: sortedCities.map((c) => c.name).toList(),
              filteredItems: filteredCities,
              onChangedFiltered: (list) =>
                  setState(() => filteredCities = list),
              onItemSelected: (value) {
                final selected = vm.cities.firstWhere((c) => c.name == value);
                vmNotifier.selectCity(selected);
                setState(() {
                  currentBarangays = sortedBarangays
                      .where((b) => b.cityCode == selected.code)
                      .toList();
                  filteredBarangays = [];
                  vm.barangayController.clear();
                });
              },
            ),
            _buildSearchField(
              label: 'Barangay',
              controller: vm.barangayController,
              isRequired: true,
              items: sortedBarangays.map((b) => b.name).toList(),
              filteredItems: filteredBarangays,
              onChangedFiltered: (list) =>
                  setState(() => filteredBarangays = list),
              onItemSelected: (value) {
                final selected = sortedBarangays.firstWhere(
                  (b) => b.name == value,
                );
                vmNotifier.selectBarangay(selected);
              },
            ),
            _buildTextField(
              'Landmark / Street',
              vmNotifier.landmarkController,
              isRequired: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: vm.isLoading
                    ? null
                    : () async {
                        setState(() => _showValidationErrors = true);

                        if (vmNotifier.firstNameController.text
                            .trim()
                            .isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('First Name is required'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        if (vmNotifier.lastNameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Last Name is required'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        if (vmNotifier.contactController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Contact Number is required'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        if (vmNotifier.cityController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Municipality is required'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        if (vmNotifier.barangayController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Barangay is required'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        if (vmNotifier.landmarkController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Landmark / Street is required'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        final success = await vmNotifier.saveCustomer();
                        if (!context.mounted) return;

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Customer saved successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          vmNotifier.resetFields();
                          setState(() => _showValidationErrors = false);
                          Navigator.pop(context, true);
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
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final showError =
        _showValidationErrors && isRequired && controller.text.trim().isEmpty;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: showError ? AppColors.error : Colors.grey,
        width: showError ? 1.4 : 1,
      ),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: showError ? AppColors.error : AppColors.textPrimary,
        width: 1.4,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        cursorColor: AppColors.textPrimary,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: (_) {
          if (_showValidationErrors) setState(() {});
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          floatingLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: focusedBorder,
        ),
      ),
    );
  }

  Widget _buildSearchField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    required List<String> items,
    required List<String> filteredItems,
    required Function(List<String>) onChangedFiltered,
    required Function(String) onItemSelected,
  }) {
    final showError =
        _showValidationErrors && isRequired && controller.text.trim().isEmpty;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: showError ? AppColors.error : Colors.grey,
        width: showError ? 1.4 : 1,
      ),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: showError ? AppColors.error : AppColors.textPrimary,
        width: 1.4,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            cursorColor: AppColors.textPrimary,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              floatingLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              filled: true,
              fillColor: Colors.white,
              border: border,
              enabledBorder: border,
              focusedBorder: focusedBorder,
            ),
            onChanged: (value) {
              final matches = items
                  .where(
                    (item) =>
                        item.toLowerCase().startsWith(value.toLowerCase()),
                  )
                  .toList();
              onChangedFiltered(matches);
              if (_showValidationErrors) setState(() {});
            },
          ),
          if (controller.text.isNotEmpty && filteredItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: filteredItems
                    .map(
                      (item) => ListTile(
                        title: Text(item),
                        onTap: () {
                          controller.text = item;
                          onItemSelected(item);
                          onChangedFiltered([]);
                          if (_showValidationErrors) setState(() {});
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
