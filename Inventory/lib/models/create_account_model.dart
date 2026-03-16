class Account {
  final String slpaName;
  final String mobileNumber;
  final String pin;
  final int? securityQuestionId;
  final String? securityAnswer;

  // NEW fields for multi-user tracking
  final String firstName;
  final String? middleName;
  final String lastName;

  Account({
    required this.slpaName,
    required this.mobileNumber,
    required this.pin,
    this.securityQuestionId,
    this.securityAnswer,
    required this.firstName,
    this.middleName,
    required this.lastName,
  });

  Map<String, dynamic> toMap() {
    return {
      'slpa_name': slpaName,
      'mobile_number': mobileNumber,
      'pin': pin,
      'security_question_id': securityQuestionId,
      'security_answer': securityAnswer,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      slpaName: (map['slpa_name'] as String?)?.trim().isNotEmpty == true
          ? map['slpa_name'] as String
          : [
              map['first_name'] as String?,
              map['middle_name'] as String?,
              map['last_name'] as String?,
            ].where((part) => (part ?? '').trim().isNotEmpty).join(' '),
      mobileNumber: map['mobile_number'] as String,
      pin: map['pin'] as String,
      securityQuestionId: map['security_question_id'] as int?,
      securityAnswer: map['security_answer'] as String?,
      firstName: (map['first_name'] as String?) ?? '',
      middleName: map['middle_name'] as String?,
      lastName: (map['last_name'] as String?) ?? '',
    );
  }
}
