// models/current_user.dart
class CurrentUser {
  static int? memberId;
  static int? accountId;
  static String? firstName;
  static String? middleName;
  static String? lastName;

  static void setFromAccount({
    required int memberId,
    required int accountId,
    required String first,
    String? middle,
    required String last,
  }) {
    CurrentUser.memberId = memberId;
    CurrentUser.accountId = accountId;
    firstName = first;
    middleName = middle;
    lastName = last;
  }

  static void clear() {
    memberId = null;
    accountId = null;
    firstName = null;
    middleName = null;
    lastName = null;
  }
}
