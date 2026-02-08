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

    final result = await db.query(
      'account',
      columns: ['id', 'first_name', 'middle_name', 'last_name', 'mobile_number', 'pin'],
      where: 'mobile_number = ? AND pin = ?',
      whereArgs: [mobileNumber.trim(), pin.trim()],
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

    final result = await db.query(
      'account',
      columns: ['id', 'first_name', 'middle_name', 'last_name', 'mobile_number', 'pin'],
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber.trim()],
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
    final middle = account.middleName?.isNotEmpty == true ? ' ${account.middleName}' : '';
    return '${account.firstName}$middle ${account.lastName}';
  }
}
