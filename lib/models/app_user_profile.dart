class AppUserProfile {
  final String id;
  final String? mobileNumber;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String status;

  const AppUserProfile({
    required this.id,
    this.mobileNumber,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.status,
  });

  factory AppUserProfile.fromMap(Map<String, dynamic> map) {
    return AppUserProfile(
      id: map['id'] as String,
      mobileNumber: map['mobile_number'] as String?,
      firstName: map['first_name'] as String? ?? '',
      middleName: map['middle_name'] as String?,
      lastName: map['last_name'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
    );
  }

  String get displayName {
    final middle = (middleName ?? '').trim();
    if (middle.isEmpty) {
      return '$firstName $lastName'.trim();
    }
    return '$firstName $middle $lastName'.trim();
  }
}
