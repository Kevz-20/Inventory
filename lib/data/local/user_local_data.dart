import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../../models/user.dart';

class UserLocalData {
  final dbHelper = DatabaseHelper.instance;

  Future<void> insertUser(User user) async {
    final db = await dbHelper.database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<User>> getAllUsers() async {
    final db = await dbHelper.database;
    final result = await db.query('users');
    return result.map((e) => User.fromMap(e)).toList();
  }
}
