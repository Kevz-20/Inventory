class LoginModel {
  final int id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String mobileNumber;
  final String pin;

  LoginModel({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.mobileNumber,
    required this.pin,
  });

  factory LoginModel.fromMap(Map<String, dynamic> map) {
    return LoginModel(
      id: map['id'] as int,
      firstName: map['first_name'] as String,
      middleName: map['middle_name'] as String?,
      lastName: map['last_name'] as String,
      mobileNumber: map['mobile_number'] as String,
      pin: map['pin'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'mobile_number': mobileNumber,
      'pin': pin,
    };
  }

  /// Optional helper: get full name
  String get fullName {
    final middle = middleName != null && middleName!.isNotEmpty ? ' $middleName' : '';
    return '$firstName$middle $lastName';
  }
}
