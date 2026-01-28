import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../../view_models/new_customer_view_model.dart';
import '../widgets/header.dart';
import '../../models/region7_psgc_model.dart';

class NewCustomerPage extends ConsumerStatefulWidget {
  const NewCustomerPage({super.key});

  @override
  ConsumerState<NewCustomerPage> createState() => _NewCustomerPageState();
}

class _NewCustomerPageState extends ConsumerState<NewCustomerPage> {
  List<String> filteredCities = [];
  List<String> filteredBarangays = [];
  List<BarangayModel> currentBarangays = [];

  @override
  Widget build(BuildContext context) {
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

    // Sort cities alphabetically
    final sortedCities = List<CityModel>.from(vm.cities)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // Sort barangays alphabetically
    final sortedBarangays = List<BarangayModel>.from(vm.barangays)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

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

            /// Municipality autocomplete
            _buildSearchField(
              label: 'Municipality',
              controller: vm.cityController,
              items: sortedCities.map((c) => c.name).toList(),
              filteredItems: filteredCities,
              onChangedFiltered: (list) =>
                  setState(() => filteredCities = list),
              onItemSelected: (value) {
                final selected = vm.cities.firstWhere((c) => c.name == value);
                vmNotifier.selectCity(selected);

                // Update current Barangays based on selected Municipality
                setState(() {
                  currentBarangays = sortedBarangays
                      .where((b) => b.cityCode == selected.code)
                      .toList();
                  filteredBarangays = [];
                  vm.barangayController.clear();
                });
              },
            ),

            /// Barangay autocomplete (independent)
            _buildSearchField(
              label: 'Barangay',
              controller: vm.barangayController,
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
                        if (success && Navigator.of(context).mounted) {
                          Navigator.of(context).pop(true);
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
        ),
      ),
    );
  }

  /// Google-style autocomplete field
  Widget _buildSearchField({
    required String label,
    required TextEditingController controller,
    required List<String> items,
    required List<String> filteredItems,
    required Function(List<String>) onChangedFiltered,
    required Function(String) onItemSelected,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              filled: true,
              fillColor: Colors.white,
              border: border,
              enabledBorder: border,
              focusedBorder: border,
            ),
            onChanged: (value) {
              final matches = items
                  .where(
                    (item) =>
                        item.toLowerCase().startsWith(value.toLowerCase()),
                  )
                  .toList();
              onChangedFiltered(matches);
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
