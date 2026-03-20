// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../models/region7_psgc_model.dart';
import '../../view_models/new_customer_view_model.dart';


class NewCustomerPage extends ConsumerStatefulWidget {
  const NewCustomerPage({super.key});

  @override
  ConsumerState<NewCustomerPage> createState() => _NewCustomerPageState();
}

class _NewCustomerPageState extends ConsumerState<NewCustomerPage> {
  static const Color _pageBg = Color(0xFFF0F4FF);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _cardBorder = Color(0xFFCDD5EE);
  static const Color _fieldBg = Color(0xFFF8FAFF);
  static const Color _titleColor = Color(0xFF1B3A7A);
  static const Color _subtitleColor = Color(0xFF5B6D96);
  static const Color _accentBlue = Color(0xFF2D5BE3);

  List<String> filteredCities = [];
  List<String> filteredBarangays = [];
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

  BoxDecoration _surfaceDecoration(double scale) {
    return BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular((22 * scale).clamp(18, 26)),
      border: Border.all(color: _cardBorder),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF93A4CF).withOpacity(0.14),
          blurRadius: (20 * scale).clamp(16, 26),
          offset: Offset(0, (10 * scale).clamp(8, 14)),
        ),
      ],
    );
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = (width / 390).clamp(0.90, 1.22);
        final horizontalPad = (16.0 * scale).clamp(14.0, 28.0);
        final topPad = (12.0 * scale).clamp(10.0, 20.0);
        final buttonHeight = (56.0 * scale).clamp(54.0, 62.0);
        final suggestMaxH =
            (MediaQuery.of(context).size.height * 0.28).clamp(180.0, 280.0);
        final isTablet = width >= 760;

        return Scaffold(
          backgroundColor: _pageBg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Image.asset(
                'lib/assets/arrowleft.png',
                width: (22 * scale).clamp(20.0, 26.0),
                height: (22 * scale).clamp(20.0, 26.0),
                fit: BoxFit.contain,
              ),
              tooltip: 'Back',
            ),
            title: Text(
              'Add New Customer',
              style: TextStyle(
                color: _titleColor,
                fontWeight: FontWeight.w900,
                fontSize: (20 * scale).clamp(18.0, 24.0),
                letterSpacing: 0.1,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: const Color(0xFFCDD5EE)),
            ),
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPad,
                        topPad,
                        horizontalPad,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIntroCard(scale),
                          SizedBox(height: (16 * scale).clamp(14, 22)),
                          Container(
                            padding: EdgeInsets.all(
                              (16 * scale).clamp(14, 22),
                            ),
                            decoration: _surfaceDecoration(scale),
                            child: Column(
                              children: [
                                  if (isTablet)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildTextField(
                                            'First Name',
                                            vmNotifier.firstNameController,
                                            scale: scale,
                                            isRequired: true,
                                            icon: Icons.person_outline_rounded,
                                            hintText: 'Juan',
                                          ),
                                        ),
                                        SizedBox(
                                          width: (12 * scale).clamp(10, 16),
                                        ),
                                        Expanded(
                                          child: _buildTextField(
                                            'Middle Name (optional)',
                                            vmNotifier.middleNameController,
                                            scale: scale,
                                            icon: Icons.person_outline_rounded,
                                            hintText: 'Dela',
                                          ),
                                        ),
                                      ],
                                    )
                                  else ...[
                                    _buildTextField(
                                      'First Name',
                                      vmNotifier.firstNameController,
                                      scale: scale,
                                      isRequired: true,
                                      icon: Icons.person_outline_rounded,
                                      hintText: 'Juan',
                                    ),
                                    _buildTextField(
                                      'Middle Name (optional)',
                                      vmNotifier.middleNameController,
                                      scale: scale,
                                      icon: Icons.person_outline_rounded,
                                      hintText: 'Dela',
                                    ),
                                  ],
                                  _buildTextField(
                                    'Last Name',
                                    vmNotifier.lastNameController,
                                    scale: scale,
                                    isRequired: true,
                                    icon: Icons.badge_outlined,
                                    hintText: 'Cruz',
                                  ),
                                  _buildTextField(
                                    'Contact Number',
                                    vmNotifier.contactController,
                                    scale: scale,
                                    isRequired: true,
                                    icon: Icons.phone_outlined,
                                    hintText: '09XXXXXXXXX',
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(11),
                                    ],
                                    validator: _contactErrorText,
                                    showValidationWhileTyping: _contactTouched,
                                    onUserInteracted: () {
                                      if (!_contactTouched) {
                                        setState(() => _contactTouched = true);
                                      }
                                    },
                                  ),
                                  if (isTablet)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildSearchField(
                                            label: 'Municipality',
                                            controller: vm.cityController,
                                            scale: scale,
                                            isRequired: true,
                                            hintText: 'Select municipality',
                                            icon: Icons.location_city_outlined,
                                            items: sortedCities
                                                .map((c) => c.name)
                                                .toList(),
                                            filteredItems: filteredCities,
                                            suggestMaxHeight: suggestMaxH,
                                            onChangedFiltered: (list) => setState(
                                              () => filteredCities = list,
                                            ),
                                            onItemSelected: (value) {
                                              final selected = vm.cities
                                                  .firstWhere(
                                                    (c) => c.name == value,
                                                  );
                                              vmNotifier.selectCity(selected);
                                              setState(() {
                                                filteredBarangays = [];
                                                vm.barangayController.clear();
                                              });
                                            },
                                          ),
                                        ),
                                        SizedBox(
                                          width: (12 * scale).clamp(10, 16),
                                        ),
                                        Expanded(
                                          child: _buildSearchField(
                                            label: 'Barangay',
                                            controller: vm.barangayController,
                                            scale: scale,
                                            isRequired: true,
                                            hintText: 'Select barangay',
                                            icon: Icons.place_outlined,
                                            items: sortedBarangays
                                                .map((b) => b.name)
                                                .toList(),
                                            filteredItems: filteredBarangays,
                                            suggestMaxHeight: suggestMaxH,
                                            onChangedFiltered: (list) => setState(
                                              () => filteredBarangays = list,
                                            ),
                                            onItemSelected: (value) {
                                              final selected = sortedBarangays
                                                  .firstWhere(
                                                    (b) => b.name == value,
                                                  );
                                              vmNotifier.selectBarangay(
                                                selected,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                  else ...[
                                    _buildSearchField(
                                      label: 'Municipality',
                                      controller: vm.cityController,
                                      scale: scale,
                                      isRequired: true,
                                      hintText: 'Select municipality',
                                      icon: Icons.location_city_outlined,
                                      items: sortedCities
                                          .map((c) => c.name)
                                          .toList(),
                                      filteredItems: filteredCities,
                                      suggestMaxHeight: suggestMaxH,
                                      onChangedFiltered: (list) => setState(
                                        () => filteredCities = list,
                                      ),
                                      onItemSelected: (value) {
                                        final selected = vm.cities.firstWhere(
                                          (c) => c.name == value,
                                        );
                                        vmNotifier.selectCity(selected);
                                        setState(() {
                                          filteredBarangays = [];
                                          vm.barangayController.clear();
                                        });
                                      },
                                    ),
                                    _buildSearchField(
                                      label: 'Barangay',
                                      controller: vm.barangayController,
                                      scale: scale,
                                      isRequired: true,
                                      hintText: 'Select barangay',
                                      icon: Icons.place_outlined,
                                      items: sortedBarangays
                                          .map((b) => b.name)
                                          .toList(),
                                      filteredItems: filteredBarangays,
                                      suggestMaxHeight: suggestMaxH,
                                      onChangedFiltered: (list) => setState(
                                        () => filteredBarangays = list,
                                      ),
                                      onItemSelected: (value) {
                                        final selected = sortedBarangays
                                            .firstWhere((b) => b.name == value);
                                        vmNotifier.selectBarangay(selected);
                                      },
                                    ),
                                  ],
                                  _buildTextField(
                                    'Landmark / Street',
                                    vmNotifier.landmarkController,
                                    scale: scale,
                                    isRequired: true,
                                    icon: Icons.edit_location_alt_outlined,
                                    hintText: 'Purok / Street / Landmark',
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: (18 * scale).clamp(16, 22)),
                          SizedBox(
                            width: double.infinity,
                            height: buttonHeight,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  (18 * scale).clamp(16, 22),
                                ),
                                gradient: LinearGradient(
                                  colors: canSave
                                      ? const [
                                          Color(0xFF275EEA),
                                          Color(0xFF43A5FF),
                                        ]
                                      : [
                                          Colors.grey.shade300,
                                          Colors.grey.shade400,
                                        ],
                                ),
                                boxShadow: canSave
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF2F6BFF,
                                          ).withOpacity(0.28),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ]
                                    : const [],
                              ),
                              child: ElevatedButton(
                                onPressed: canSave
                                    ? () async {
                                        await _saveCustomer(vmNotifier);
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  surfaceTintColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      (18 * scale).clamp(16, 22),
                                    ),
                                  ),
                                ),
                                child: vm.isLoading
                                    ? SizedBox(
                                        height: (22 * scale).clamp(22, 26),
                                        width: (22 * scale).clamp(22, 26),
                                        child:
                                            const CircularProgressIndicator(
                                              strokeWidth: 2.6,
                                              color: Colors.white,
                                            ),
                                      )
                                    : Text(
                                        'Add Customer',
                                        style: TextStyle(
                                          fontSize:
                                              (17 * scale).clamp(16, 19),
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveCustomer(NewCustomerViewModel vmNotifier) async {
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
    if (!mounted) return;

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
        filteredCities = [];
        filteredBarangays = [];
      });
      Navigator.pop(context, true);
    }
  }

  Widget _buildIntroCard(double scale) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all((18 * scale).clamp(16, 24)),
      decoration: _surfaceDecoration(scale).copyWith(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDFEFF), Color(0xFFF3F7FF)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: (52 * scale).clamp(48, 60),
            height: (52 * scale).clamp(48, 60),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular((16 * scale).clamp(14, 18)),
              gradient: const LinearGradient(
                colors: [Color(0xFFECF3FF), Color(0xFFD8E8FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.person_add_alt_1_rounded,
              color: _accentBlue,
              size: (28 * scale).clamp(24, 32),
            ),
          ),
          SizedBox(width: (14 * scale).clamp(12, 18)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Information',
                  style: TextStyle(
                    color: _titleColor,
                    fontSize: (18 * scale).clamp(17, 21),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    required double scale,
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
    final double radius = (18 * scale).clamp(16.0, 20.0).toDouble();

    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(
        color: showError ? AppColors.error : _cardBorder,
        width: showError ? 1.4 : 1,
      ),
      );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(
        color: showError ? AppColors.error : _accentBlue,
        width: 1.6,
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: (7 * scale).clamp(6, 10)),
      child: TextFormField(
        controller: controller,
        cursorColor: _titleColor,
        style: TextStyle(
          color: _titleColor,
          fontWeight: FontWeight.w700,
          fontSize: (15 * scale).clamp(14, 16),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: (_) {
          onUserInteracted?.call();
          if (_showValidationErrors || showValidationWhileTyping) {
            setState(() {});
          }
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          filled: true,
          fillColor: _fieldBg,
          prefixIcon: icon != null
              ? Icon(icon, color: _subtitleColor.withOpacity(0.88))
              : null,
          contentPadding: EdgeInsets.symmetric(
            horizontal: (16 * scale).clamp(14, 18),
            vertical: (16 * scale).clamp(15, 19),
          ),
          hintStyle: TextStyle(
            color: _subtitleColor.withOpacity(0.68),
            fontWeight: FontWeight.w500,
          ),
          labelStyle: TextStyle(
            color: showError ? AppColors.error : _subtitleColor,
            fontWeight: FontWeight.w700,
          ),
          floatingLabelStyle: TextStyle(
            color: showError ? AppColors.error : _accentBlue,
            fontWeight: FontWeight.w900,
          ),
          border: baseBorder,
          enabledBorder: baseBorder,
          focusedBorder: focusedBorder,
          helperText: showFormatError ? formatError : null,
          helperStyle: const TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
          ),
          errorText: showEmptyError ? '' : null,
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
    required double scale,
    bool isRequired = false,
    String? hintText,
    IconData? icon,
  }) {
    final showError =
        _showValidationErrors && isRequired && controller.text.trim().isEmpty;
    final double radius = (18 * scale).clamp(16.0, 20.0).toDouble();

    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(
        color: showError ? AppColors.error : _cardBorder,
        width: showError ? 1.4 : 1,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(
        color: showError ? AppColors.error : _accentBlue,
        width: 1.6,
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: (7 * scale).clamp(6, 10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            cursorColor: _titleColor,
            style: TextStyle(
              color: _titleColor,
              fontWeight: FontWeight.w700,
              fontSize: (15 * scale).clamp(14, 16),
            ),
            decoration: InputDecoration(
              labelText: label,
              hintText: hintText,
              filled: true,
              fillColor: _fieldBg,
              prefixIcon: icon != null
                  ? Icon(icon, color: _subtitleColor.withOpacity(0.88))
                  : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: (16 * scale).clamp(14, 18),
                vertical: (16 * scale).clamp(15, 19),
              ),
              hintStyle: TextStyle(
                color: _subtitleColor.withOpacity(0.68),
                fontWeight: FontWeight.w500,
              ),
              labelStyle: TextStyle(
                color: showError ? AppColors.error : _subtitleColor,
                fontWeight: FontWeight.w700,
              ),
              floatingLabelStyle: TextStyle(
                color: showError ? AppColors.error : _accentBlue,
                fontWeight: FontWeight.w900,
              ),
              border: baseBorder,
              enabledBorder: baseBorder,
              focusedBorder: focusedBorder,
              errorText: showError ? '' : null,
              errorStyle: const TextStyle(height: 0, fontSize: 0),
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
              margin: const EdgeInsets.only(top: 8),
              constraints: BoxConstraints(maxHeight: suggestMaxHeight),
              decoration: _surfaceDecoration(scale).copyWith(
                borderRadius: BorderRadius.circular(radius),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.location_on_outlined,
                      color: _accentBlue.withOpacity(0.85),
                      size: (20 * scale).clamp(18, 22),
                    ),
                    title: Text(
                      item,
                      style: TextStyle(
                        color: _titleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: (14 * scale).clamp(13, 15),
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
