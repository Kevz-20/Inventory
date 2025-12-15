import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class ChangePinRepository {
  final Database db;

  ChangePinRepository(this.db);

  Future<int?> getAccountId() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString('mobileNumber');

    if (mobile == null) {
      return null; // no mobile saved
    }

    final result = await db.query(
      'account',
      columns: ['id'],
      where: 'mobile_number = ?',
      whereArgs: [mobile],
      limit: 1,
    );

    if (result.isEmpty) {
      return null; // account not found
    }

    return result.first['id'] as int;
  }

  Future<bool> changePin(int id, String oldPin, String newPin) async {
    final result = await db.query(
      'account',
      columns: ['pin'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty || result.first['pin'] != oldPin) {
      return false;
    }

    await db.update(
      'account',
      {'pin': newPin},
      where: 'id = ?',
      whereArgs: [id],
    );

    return true;
  }

  Future<void> saveMobileNumber(String mobile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mobileNumber', mobile);
  }
}
