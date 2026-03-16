class LoginModel {
  final int accountId;
  final int memberId;
  final int id;
  final String slpaName;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String mobileNumber;
  final String pin;

  LoginModel({
    required this.accountId,
    required this.memberId,
    required this.id,
    required this.slpaName,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.mobileNumber,
    required this.pin,
  });

  factory LoginModel.fromMap(Map<String, dynamic> map) {
    return LoginModel(
      accountId: (map['account_id'] as num?)?.toInt() ?? 0,
      memberId: (map['member_id'] as num?)?.toInt() ?? (map['id'] as num?)?.toInt() ?? 0,
      id: map['id'] as int,
      slpaName: (map['slpa_name'] as String?)?.trim().isNotEmpty == true
          ? map['slpa_name'] as String
          : [
              map['first_name'] as String?,
              map['middle_name'] as String?,
              map['last_name'] as String?,
            ].where((part) => (part ?? '').trim().isNotEmpty).join(' '),
      firstName: (map['first_name'] as String?) ?? '',
      middleName: map['middle_name'] as String?,
      lastName: (map['last_name'] as String?) ?? '',
      mobileNumber: map['mobile_number'] as String,
      pin: map['pin'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'account_id': accountId,
      'member_id': memberId,
      'id': id,
      'slpa_name': slpaName,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'mobile_number': mobileNumber,
      'pin': pin,
    };
  }

  String get fullName {
    return [firstName, middleName, lastName]
        .where((part) => (part ?? '').trim().isNotEmpty)
        .join(' ');
  }
}
