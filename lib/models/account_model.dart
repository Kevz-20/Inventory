class Account {
  final int? id;
  final String mobileNumber;
  final String pin;
  final int? securityQuestionId;
  final String? securityAnswer;

  // User name fields
  final String firstName;
  final String? middleName;
  final String lastName;

  // Profile image
  final String? profileImage;

  Account({
    this.id,
    required this.mobileNumber,
    required this.pin,
    this.securityQuestionId,
    this.securityAnswer,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.profileImage,
  });

  /// Create Account from Map (DB / API)
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      mobileNumber: map['mobile_number'] as String,
      pin: map['pin'] as String,
      securityQuestionId: map['security_question_id'] as int?,
      securityAnswer: map['security_answer'] as String?,
      firstName: map['first_name'] as String,
      middleName: map['middle_name'] as String?,
      lastName: map['last_name'] as String,
      profileImage: map['profile_image'] as String?,
    );
  }

  /// Convert Account to Map (for DB / API)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'mobile_number': mobileNumber,
      'pin': pin,
      'security_question_id': securityQuestionId,
      'security_answer': securityAnswer,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'profile_image': profileImage,
    };
  }
}

extension AccountCopy on Account {
  Account copyWith({
    String? mobileNumber, // <-- add this
    String? securityAnswer,
    String? firstName,
    String? middleName,
    String? lastName,
    String? profileImage,
  }) {
    return Account(
      id: id,
      mobileNumber: mobileNumber ?? this.mobileNumber, // <-- update here
      pin: pin,
      securityAnswer: securityAnswer ?? this.securityAnswer,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
