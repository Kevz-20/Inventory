import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../../view_models/new_customer_view_model.dart';

class NewCustomerPage extends ConsumerStatefulWidget {
  const NewCustomerPage({super.key});

  @override
  ConsumerState<NewCustomerPage> createState() => _NewCustomerPageState();
}

class _NewCustomerPageState extends ConsumerState<NewCustomerPage> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final vmNotifier = ref.read(newCustomerViewModelProvider);
    final vm = ref.watch(newCustomerViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Customer')),
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
            _buildTextField('Municipality', vmNotifier.municipalityController),
            _buildTextField('Barangay', vmNotifier.barangayController),
            _buildTextField('Landmark / Street', vmNotifier.landmarkController),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isSaving || vm.isLoading)
                    ? null
                    : () async {
                        setState(() => _isSaving = true);

                        final result = await vmNotifier.saveCustomer();

                        if (!mounted) return; // check before using context

                        // Show SnackBar safely
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        if (messenger != null) {
                          if (result == true) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Customer added successfully!'),
                              ),
                            );
                            Navigator.of(context).pop(true);
                          } else if (result == false) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Failed to add customer!'),
                              ),
                            );
                          } else if (result is String) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(result)),
                            );
                          }
                        }

                        setState(() => _isSaving = false);
                      },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Colors.blue,
                ),
                child: (_isSaving || vm.isLoading)
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Customer',
                        style: TextStyle(color: Colors.white),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          fillColor: Colors.white,
          filled: true,
        ),
      ),
    );
  }
}
