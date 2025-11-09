import '../services/db_service.dart';
import '../models/login_model.dart';

class LoginRepository {
  final DBService _dbService;

  LoginRepository(this._dbService);

  // Get account by mobile number
  Future<LoginModel?> getAccount(String mobileNumber, String pin) async {
    final db = await _dbService.database;
    final result = await db.query(
      'account',
      columns: ['mobile_number', 'pin'],
      where: 'mobile_number = ? AND pin = ?',
      whereArgs: [mobileNumber, pin],
    );

    if (result.isNotEmpty) {
      return LoginModel.fromMap(result.first);
    }
    return null;
  }

  // Optional: fetch only by mobile number
  Future<LoginModel?> getAccountByMobileNumber(String mobileNumber) async {
    final db = await _dbService.database;
    final result = await db.query(
      'account',
      columns: ['mobile_number', 'pin'],
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber],
    );

    if (result.isNotEmpty) {
      return LoginModel.fromMap(result.first);
    }
    return null;
  }

  // Verify PIN
  Future<bool> verifyPin(String mobileNumber, String pin) async {
    final account = await getAccountByMobileNumber(mobileNumber);
    if (account == null) return false;
    return account.pin == pin;
  }
}
