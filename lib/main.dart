import 'package:flutter/material.dart';
import 'data/local/user_local_data.dart';
import 'models/user.dart';
import 'data/local/database_helper.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.database;
  debugPrint('✅ SQLite database initialized and tables created.');

  final userLocalData = UserLocalData();

  // Insert sample user
  await userLocalData.insertUser(User(name: 'Awen', email: 'awen@example.com'));

  // Retrieve all users
  final users = await userLocalData.getAllUsers();
  for (var u in users) {
    debugPrint('👤 ${u.name} - ${u.email}');
  }

  runApp(const MyApp());
}
