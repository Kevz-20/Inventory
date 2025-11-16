class ForgotPinModel {
  final String mobileNumber;
  final int securityQuestionId;
  final String securityAnswer;
  final String pin;

  ForgotPinModel({
    required this.mobileNumber,
    required this.securityQuestionId,
    required this.securityAnswer,
    required this.pin,
  });

  Map<String, dynamic> toMap() {
    return {
      'mobile_number': mobileNumber,
      'security_question_id': securityQuestionId,
      'security_answer': securityAnswer,
      'pin': pin,
    };
  }

  factory ForgotPinModel.fromMap(Map<String, dynamic> map) {
    return ForgotPinModel(
      mobileNumber: map['mobile_number'],
      securityQuestionId: map['security_question_id'],
      securityAnswer: map['security_answer'],
      pin: map['pin'] ?? '',
    );
  }
}
