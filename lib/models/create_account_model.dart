class Account {
  final String mobileNumber;
  final String? associationName;
  final String pin;
  final int? securityQuestionId;
  final String? securityAnswer;

  Account({
    required this.mobileNumber,
    this.associationName,
    required this.pin,
    this.securityQuestionId,
    this.securityAnswer,
  });

  Map<String, dynamic> toMap() {
    return {
      'mobile_number': mobileNumber,
      'association_name': associationName,
      'pin': pin,
      'security_question_id': securityQuestionId,
      'security_answer': securityAnswer,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      mobileNumber: map['mobile_number'] as String,
      associationName: map['association_name'] as String?,
      pin: map['pin'] as String,
      securityQuestionId: map['security_question_id'] as int?,
      securityAnswer: map['security_answer'] as String?,
    );
  }
}
