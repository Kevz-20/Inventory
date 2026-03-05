// ignore_for_file: deprecated_member_use

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

  bool _contactTouched = false;

  String? _contactErrorText(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;

    if (!RegExp(r'^\d+$').hasMatch(v)) return 'Numbers only';
    if (v.length != 11) return 'Contact number must be 11 digits';
    if (!v.startsWith('09')) return 'Contact number must start with 09';
    return null;
  }

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

    final canSave = !vm.isLoading && vm.isFormValid;

    // ✅ Responsive scale (small phone -> tablet)
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final s = (w / 360).clamp(1.0, 1.18);

    // ✅ Responsive paddings (keeps your same layout, just adapts spacing)
    final padH = (16.0 * s).clamp(16.0, 24.0);
    final padV = (16.0 * s).clamp(16.0, 24.0);

    // ✅ Responsive list max height
    final suggestMaxH = (h * 0.28).clamp(180.0, 280.0);

    // ✅ Responsive button height
    final buttonH = (52.0 * s).clamp(52.0, 60.0);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Add New Customer', showBackButton: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(padH, padV, padH, 24),
        child: Column(
          children: [
            _sectionHeader(title: "Customer Information", s: s),
            SizedBox(height: (12 * s).clamp(12.0, 16.0)),

            _buildTextField(
              'First Name',
              vmNotifier.firstNameController,
              s: s,
              isRequired: true,
              icon: Icons.person_outline,
              hintText: "Juan",
            ),

            _buildTextField(
              'Middle Name (optional)',
              vmNotifier.middleNameController,
              s: s,
              icon: Icons.person_outline,
              hintText: "Dela",
            ),

            _buildTextField(
              'Last Name',
              vmNotifier.lastNameController,
              s: s,
              isRequired: true,
              icon: Icons.person_outline,
              hintText: "Cruz",
            ),

            _buildTextField(
              'Contact Number',
              vmNotifier.contactController,
              s: s,
              isRequired: true,
              icon: Icons.phone_outlined,
              hintText: "09XXXXXXXXX",
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              validator: _contactErrorText,
              showValidationWhileTyping: _contactTouched,
              onUserInteracted: () {
                if (!_contactTouched) setState(() => _contactTouched = true);
              },
            ),

            _buildSearchField(
              label: 'Municipality',
              controller: vm.cityController,
              s: s,
              isRequired: true,
              hintText: "Select municipality",
              icon: Icons.location_city_outlined,
              items: sortedCities.map((c) => c.name).toList(),
              filteredItems: filteredCities,
              suggestMaxHeight: suggestMaxH,
              onChangedFiltered: (list) => setState(() => filteredCities = list),
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
              s: s,
              isRequired: true,
              hintText: "Select barangay",
              icon: Icons.place_outlined,
              items: sortedBarangays.map((b) => b.name).toList(),
              filteredItems: filteredBarangays,
              suggestMaxHeight: suggestMaxH,
              onChangedFiltered: (list) => setState(() => filteredBarangays = list),
              onItemSelected: (value) {
                final selected = sortedBarangays.firstWhere((b) => b.name == value);
                vmNotifier.selectBarangay(selected);
              },
            ),

            _buildTextField(
              'Landmark / Street',
              vmNotifier.landmarkController,
              s: s,
              isRequired: true,
              icon: Icons.edit_location_alt_outlined,
              hintText: "Purok / Street / Landmark",
            ),

            SizedBox(height: (18 * s).clamp(18.0, 24.0)),

            SizedBox(
              width: double.infinity,
              height: buttonH,
              child: ElevatedButton(
                onPressed: canSave
                    ? () async {
                        setState(() => _showValidationErrors = true);

                        if (vmNotifier.firstNameController.text.trim().isEmpty) {
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

                        final contactFormatError =
                            _contactErrorText(vmNotifier.contactController.text);
                        if (contactFormatError != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(contactFormatError),
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
                          setState(() {
                            _showValidationErrors = false;
                            _contactTouched = false;
                          });
                          Navigator.pop(context, true);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSave ? AppColors.primary : Colors.grey.shade400,
                  disabledBackgroundColor: Colors.grey.shade400,
                  elevation: canSave ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular((16 * s).clamp(16.0, 20.0)),
                  ),
                ),
                child: vm.isLoading
                    ? SizedBox(
                        height: (22 * s).clamp(22.0, 26.0),
                        width: (22 * s).clamp(22.0, 26.0),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Add Customer',
                        style: TextStyle(
                          fontSize: (16 * s).clamp(16.0, 18.0),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // UI HELPERS
  // -------------------------

  Widget _sectionHeader({required String title, required double s}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all((14 * s).clamp(14.0, 18.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular((16 * s).clamp(16.0, 20.0)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: (16 * s).clamp(16.0, 18.0),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    required double s,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    IconData? icon,
    String? hintText,
    String? Function(String value)? validator,
    bool showValidationWhileTyping = false,
    VoidCallback? onUserInteracted,
  }) {
    final isEmpty = controller.text.trim().isEmpty;
    final formatError = validator?.call(controller.text);

    final showEmptyError = _showValidationErrors && isRequired && isEmpty;
    final showFormatError =
        (_showValidationErrors || showValidationWhileTyping) &&
        !isEmpty &&
        formatError != null;

    final showError = showEmptyError || showFormatError;

    final radius = (14 * s).clamp(14.0, 18.0);

    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(
        color: showError ? AppColors.error : Colors.grey.shade300,
        width: showError ? 1.4 : 1,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(
        color: showError ? AppColors.error : AppColors.primary,
        width: 1.6,
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: (8 * s).clamp(8.0, 12.0)),
      child: TextFormField(
        controller: controller,
        cursorColor: AppColors.textPrimary,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: (_) {
          onUserInteracted?.call();
          if (_showValidationErrors || showValidationWhileTyping) setState(() {});
        },
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelText: label,
          hintText: hintText,
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade600) : null,
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding: EdgeInsets.symmetric(
            horizontal: (14 * s).clamp(14.0, 18.0),
            vertical: (14 * s).clamp(14.0, 18.0),
          ),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w700,
            color: showError ? AppColors.error : AppColors.textPrimary,
          ),
          floatingLabelStyle: TextStyle(
            fontWeight: FontWeight.w900,
            color: showError ? AppColors.error : AppColors.primary,
          ),
          border: baseBorder,
          enabledBorder: baseBorder,
          focusedBorder: focusedBorder,
          helperText: showFormatError ? formatError : null,
          helperStyle: const TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
          ),
          errorText: showEmptyError ? "" : null,
          errorStyle: const TextStyle(height: 0, fontSize: 0),
        ),
      ),
    );
  }

  Widget _buildSearchField({
    required String label,
    required TextEditingController controller,
    required List<String> items,
    required List<String> filteredItems,
    required Function(List<String>) onChangedFiltered,
    required Function(String) onItemSelected,
    required double suggestMaxHeight,
    required double s,
    bool isRequired = false,
    String? hintText,
    IconData? icon,
  }) {
    final showError = _showValidationErrors && isRequired && controller.text.trim().isEmpty;
    final radius = (14 * s).clamp(14.0, 18.0);

    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(
        color: showError ? AppColors.error : Colors.grey.shade300,
        width: showError ? 1.4 : 1,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(
        color: showError ? AppColors.error : AppColors.primary,
        width: 1.6,
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: (8 * s).clamp(8.0, 12.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            cursorColor: AppColors.textPrimary,
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              labelText: label,
              hintText: hintText,
              prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade600) : null,
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: EdgeInsets.symmetric(
                horizontal: (14 * s).clamp(14.0, 18.0),
                vertical: (14 * s).clamp(14.0, 18.0),
              ),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                color: showError ? AppColors.error : AppColors.textPrimary,
              ),
              floatingLabelStyle: TextStyle(
                fontWeight: FontWeight.w900,
                color: showError ? AppColors.error : AppColors.primary,
              ),
              border: baseBorder,
              enabledBorder: baseBorder,
              focusedBorder: focusedBorder,
              errorText: showError ? "" : null,
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
            onChanged: (value) {
              final matches = items
                  .where((item) => item.toLowerCase().startsWith(value.toLowerCase()))
                  .toList();
              onChangedFiltered(matches);
              if (_showValidationErrors) setState(() {});
            },
          ),
          if (controller.text.isNotEmpty && filteredItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              constraints: BoxConstraints(maxHeight: suggestMaxHeight),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      item,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: (13 * s).clamp(13.0, 15.0),
                      ),
                    ),
                    onTap: () {
                      controller.text = item;
                      onItemSelected(item);
                      onChangedFiltered([]);
                      if (_showValidationErrors) setState(() {});
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}