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
  String? snackbarMessage;

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

  void _setSnackbar(String message) {
    snackbarMessage = message;
    notifyListeners();
  }

  Future<bool> saveCustomer() async {
    if (_repo == null) {
      _setSnackbar('Database not ready, try again later');
      return false;
    }

    final contact = contactController.text.trim();
    final regex = RegExp(r'^09\d{9}$');

    if (firstNameController.text.trim().isEmpty) {
      _setSnackbar('First Name is required');
      return false;
    }

    if (lastNameController.text.trim().isEmpty) {
      _setSnackbar('Last Name is required');
      return false;
    }

    if (!regex.hasMatch(contact)) {
      _setSnackbar('Contact number must start with 09 and be 11 digits');
      return false;
    }

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

      firstNameController.clear();
      middleNameController.clear();
      lastNameController.clear();
      contactController.clear();
      municipalityController.clear();
      barangayController.clear();
      landmarkController.clear();

      isLoading = false;
      notifyListeners();

      _setSnackbar('Customer added successfully!');
      return true;
    } catch (e) {
      debugPrint('Error saving customer: $e');
      isLoading = false;
      _setSnackbar('Failed to add customer!');
      notifyListeners();
      return false;
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
