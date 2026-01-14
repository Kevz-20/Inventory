class Account {
  final int? id;
  final String mobileNumber;
  final String? associationName;
  final String pin;
  final int? securityQuestionId;
  final String? securityAnswer;
    final String? profileImage;

 // var name;


  Account({
    this.id,
    required this.mobileNumber,
    this.associationName,
    required this.pin,
    this.securityQuestionId,
    this.securityAnswer,
     this.profileImage,
  });

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      mobileNumber: map['mobile_number'] as String,
      associationName: map['association_name'] as String?,
      pin: map['pin'] as String,
      securityQuestionId: map['security_question_id'] as int?,
      securityAnswer: map['security_answer'] as String?,
       profileImage: map['profile_image'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'mobile_number': mobileNumber,
      'association_name': associationName,
      'pin': pin,
      'security_question_id': securityQuestionId,
      'security_answer': securityAnswer,
      'profile_image': profileImage,
    };
  }
}
extension AccountCopy on Account {
  Account copyWith({
    String? associationName,
    String? securityAnswer,
    String? profileImage,
  }) {
    return Account(
      id: id,
      mobileNumber: mobileNumber,
      associationName: associationName ?? this.associationName,
      pin: pin,
      securityAnswer: securityAnswer ?? this.securityAnswer,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
