import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../services/db_service.dart'; // ✅ adjust path if your DBService is elsewhere

/// Provides the opened SQLite database (from your existing DBService)
final databaseProvider = FutureProvider<Database>((ref) async {
  return await DBService.instance.database;
});