class LoginModel {
  final String mobileNumber;
  final String pin;

  LoginModel({required this.mobileNumber, required this.pin});

  factory LoginModel.fromMap(Map<String, dynamic> map) {
    return LoginModel(
      mobileNumber: map['mobile_number'] as String,
      pin: map['pin'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'mobile_number': mobileNumber, 'pin': pin};
  }
}
