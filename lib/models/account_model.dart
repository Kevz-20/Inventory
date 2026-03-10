class Account {
  final int? id;
  final String mobileNumber;
  final String pin;
  final int? securityQuestionId;
  final String? securityAnswer;

  /// The question text joined from the security_questions table.
  /// Not stored in the account table — populated via JOIN queries only.
  final String? securityQuestion;

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
    this.securityQuestion,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.profileImage,
  });

  /// Create Account from Map (DB / API).
  /// If the map includes a joined `security_question` column it will be
  /// picked up automatically — no schema change required.
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      mobileNumber: map['mobile_number'] as String,
      pin: map['pin'] as String,
      securityQuestionId: map['security_question_id'] as int?,
      securityAnswer: map['security_answer'] as String?,
      securityQuestion: map['security_question'] as String?,
      firstName: map['first_name'] as String,
      middleName: map['middle_name'] as String?,
      lastName: map['last_name'] as String,
      profileImage: map['profile_image'] as String?,
    );
  }

  /// Convert Account to Map (for DB / API).
  /// securityQuestion is intentionally excluded — it is read-only display
  /// data derived from the JOIN, not a column in the account table.
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
    String? mobileNumber,
    String? securityAnswer,
    String? securityQuestion,
    String? firstName,
    String? middleName,
    String? lastName,
    String? profileImage,
  }) {
    return Account(
      id: id,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      pin: pin,
      securityQuestionId: securityQuestionId,
      securityAnswer: securityAnswer ?? this.securityAnswer,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}