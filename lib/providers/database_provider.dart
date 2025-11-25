import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/db_service.dart';
import 'package:sqflite/sqflite.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  return await DBService.instance.database;
});
