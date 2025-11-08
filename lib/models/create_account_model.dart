class Account {
  final int? id;
  final String? associationName;
  final String phoneNumber;
  final String pin;
  final int? securityQuestionId;
  final String? securityAnswer;

  Account({
    this.id,
    this.associationName,
    required this.phoneNumber,
    required this.pin,
    this.securityQuestionId,
    this.securityAnswer,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'association_name': associationName,
      'phone_number': phoneNumber,
      'pin': pin,
      'security_question_id': securityQuestionId,
      'security_answer': securityAnswer,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      associationName: map['association_name'] as String?,
      phoneNumber: map['phone_number'] as String,
      pin: map['pin'] as String,
      securityQuestionId: map['security_question_id'] as int?,
      securityAnswer: map['security_answer'] as String?,
    );
  }
}
