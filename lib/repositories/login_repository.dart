import '../services/db_service.dart';
import '../models/login_model.dart';

class LoginRepository {
  final DBService _dbService;

  LoginRepository(this._dbService);

  /// -------------------------
  /// LOGIN WITH MOBILE NUMBER + PIN
  /// -------------------------
  Future<LoginModel?> getAccount(String mobileNumber, String pin) async {
    final db = await _dbService.database;

    final result = await db.rawQuery(
      '''
      SELECT
        m.id AS member_id,
        a.id AS account_id,
        a.id AS id,
        a.slpa_name,
        m.first_name,
        m.middle_name,
        m.last_name,
        m.mobile_number,
        m.pin
      FROM slpa_member m
      INNER JOIN account a ON a.id = m.account_id
      WHERE m.mobile_number = ? AND m.pin = ?
      LIMIT 1
      ''',
      [mobileNumber.trim(), pin.trim()],
    );

    if (result.isNotEmpty) {
      return LoginModel.fromMap(result.first);
    }
    return null;
  }

  /// -------------------------
  /// FETCH ACCOUNT BY MOBILE NUMBER ONLY
  /// -------------------------
  Future<LoginModel?> getAccountByMobileNumber(String mobileNumber) async {
    final db = await _dbService.database;

    final result = await db.rawQuery(
      '''
      SELECT
        m.id AS member_id,
        a.id AS account_id,
        a.id AS id,
        a.slpa_name,
        m.first_name,
        m.middle_name,
        m.last_name,
        m.mobile_number,
        m.pin
      FROM slpa_member m
      INNER JOIN account a ON a.id = m.account_id
      WHERE m.mobile_number = ?
      LIMIT 1
      ''',
      [mobileNumber.trim()],
    );

    if (result.isNotEmpty) {
      return LoginModel.fromMap(result.first);
    }
    return null;
  }

  /// -------------------------
  /// VERIFY PIN FOR LOGIN
  /// -------------------------
  Future<bool> verifyPin(String mobileNumber, String pin) async {
    final account = await getAccountByMobileNumber(mobileNumber.trim());
    if (account == null) return false;
    return account.pin == pin.trim();
  }

  /// -------------------------
  /// FETCH FULL NAME
  /// -------------------------
  Future<String?> getFullName(String mobileNumber) async {
    final account = await getAccountByMobileNumber(mobileNumber.trim());
    if (account == null) return null;
    return account.fullName;
  }
}
