import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/region7_psgc.dart';
import '../models/region7_psgc_model.dart';
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
  TextEditingController cityController = TextEditingController();

  // Region 7
  RegionModel? selectedRegion;
  CityModel? selectedCity;
  BarangayModel? selectedBarangay;

  List<CityModel> cities = [];
  List<BarangayModel> barangays = [];

  NewCustomerViewModel() {
    _initRepository();
    _loadRegion7();
  }

  /// Initialize database repository
  Future<void> _initRepository() async {
  final db = await DBService.instance.database;
  _repo = CustomerRepository(db); // ✅ only pass DB, no AccountRepository
  }

  /// Load Region VII data and flatten cities
  void _loadRegion7() {
    final region = RegionModel.fromList(region7Data);
    selectedRegion = region;

    // Flatten all cities from all provinces in the region
    cities = region.provinces.expand((p) => p.cities).toList();

    notifyListeners();
  }

  /// Select a city (municipality) and load its barangays
  void selectCity(CityModel city) {
    selectedCity = city;
    barangays = city.barangays;
    selectedBarangay = null;
    municipalityController.text = city.name;
    barangayController.text = '';
    notifyListeners();
  }

  /// Select a barangay
  void selectBarangay(BarangayModel barangay) {
    selectedBarangay = barangay;
    barangayController.text = barangay.name;
    notifyListeners();
  }

  /// Validate customer form
  bool validateForm() {
    final contact = contactController.text.trim();
    final regex = RegExp(r'^09\d{9}$');
    return firstNameController.text.trim().isNotEmpty &&
        lastNameController.text.trim().isNotEmpty &&
        contact.isNotEmpty &&
        regex.hasMatch(contact);
  }

  /// Set snackbar message
  void _setSnackbar(String message) {
    snackbarMessage = message;
    notifyListeners();
  }

  /// Save customer to database
  Future<bool> saveCustomer() async {
  if (_repo == null) {
    _setSnackbar('Database not ready, try again later');
    return false;
  }

  final firstName = firstNameController.text.trim();
  final middleName = middleNameController.text.trim();
  final lastName = lastNameController.text.trim();
  final contact = contactController.text.trim();

  final regex = RegExp(r'^09\d{9}$');

  if (firstName.isEmpty) {
    _setSnackbar('First Name is required');
    return false;
  }

  if (lastName.isEmpty) {
    _setSnackbar('Last Name is required');
    return false;
  }

  if (!regex.hasMatch(contact)) {
    _setSnackbar('Contact number must start with 09 and be 11 digits');
    return false;
  }

  isLoading = true;
  notifyListeners();

  try {
    // ✅ CHECK DUPLICATES FIRST
    final phoneExists = await _repo!.isPhoneExists(contact);
    final nameExists =
        await _repo!.isNameExists(firstName, middleName, lastName);

    if (phoneExists && nameExists) {
      isLoading = false;
      _setSnackbar('Customer name and phone number already exist.');
      return false;
    }

    if (phoneExists) {
      isLoading = false;
      _setSnackbar('Phone number already exists.');
      return false;
    }

    if (nameExists) {
      isLoading = false;
      _setSnackbar('Customer name already exists.');
      return false;
    }

    final customer = {
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'phone_number': contact,
      'municipality': municipalityController.text.trim(),
      'barangay': barangayController.text.trim(),
      'landmark': landmarkController.text.trim(),
    };

    await _repo!.insertCustomer(customer);

    // Clear fields
    firstNameController.clear();
    middleNameController.clear();
    lastNameController.clear();
    contactController.clear();
    municipalityController.clear();
    barangayController.clear();
    landmarkController.clear();
    selectedCity = null;
    selectedBarangay = null;
    barangays = [];

    isLoading = false;
    notifyListeners();

    return true;
  } catch (e) {
    debugPrint('Error saving customer: $e');
    isLoading = false;
    _setSnackbar('Unexpected error occurred.');
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
