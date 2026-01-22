import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/customer_repository.dart';
import '../services/db_service.dart';

final newCustomerViewModelProvider =
    ChangeNotifierProvider<NewCustomerViewModel>(
      (ref) => NewCustomerViewModel(),
    );

class NewCustomerViewModel extends ChangeNotifier {
  CustomerRepository? _repo;

  bool isLoading = false;

  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final contactController = TextEditingController();
  final municipalityController = TextEditingController();
  final barangayController = TextEditingController();
  final landmarkController = TextEditingController();

  NewCustomerViewModel() {
    _initRepository();
  }

  Future<void> _initRepository() async {
    final db = await DBService.instance.database;
    _repo = CustomerRepository(db);
  }

  bool validateForm() {
    final contact = contactController.text.trim();
    final regex = RegExp(r'^09\d{9}$');
    return firstNameController.text.trim().isNotEmpty &&
        lastNameController.text.trim().isNotEmpty &&
        contact.isNotEmpty &&
        regex.hasMatch(contact);
  }

  /// Save customer and notify UI
  Future<void> saveCustomer(BuildContext context) async {
    // Check if repository is ready
    if (_repo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database not ready, try again later')),
      );
      return;
    }

    final contact = contactController.text.trim();
    final regex = RegExp(r'^09\d{9}$'); // Must start with 09 and 11 digits

    // Validate fields with user feedback
    if (firstNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('First Name is required')));
      return;
    }

    if (lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Last Name is required')));
      return;
    }

    if (!regex.hasMatch(contact)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact number must start with 09 and be 11 digits'),
        ),
      );
      return;
    }

    // Show loading
    isLoading = true;
    notifyListeners();

    final customer = {
      'first_name': firstNameController.text.trim(),
      'middle_name': middleNameController.text.trim(),
      'last_name': lastNameController.text.trim(),
      'phone_number': contact,
      'municipality': municipalityController.text.trim(),
      'barangay': barangayController.text.trim(),
      'landmark': landmarkController.text.trim(),
    };

    try {
      await _repo!.insertCustomer(customer);

      // Clear fields after successful save
      firstNameController.clear();
      middleNameController.clear();
      lastNameController.clear();
      contactController.clear();
      municipalityController.clear();
      barangayController.clear();
      landmarkController.clear();

      isLoading = false;
      notifyListeners();

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer added successfully!')),
      );

      // ✅ New: Pop page and return true to indicate a new customer was added
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Error saving customer: $e');
      isLoading = false;
      notifyListeners();

      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add customer!')));
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    contactController.dispose();
    municipalityController.dispose();
    barangayController.dispose();
    landmarkController.dispose();
    super.dispose();
  }
}
