// models/current_user.dart
class CurrentUser {
  static String? firstName;
  static String? middleName;
  static String? lastName;

  /// ✅ Set current user from account
  static void setFromAccount({
    required String first,
    String? middle,
    required String last,
  }) {
    firstName = first;
    middleName = middle;
    lastName = last;
  }

  /// Clear current user info
  static void clear() {
    firstName = null;
    middleName = null;
    lastName = null;
  }
}
