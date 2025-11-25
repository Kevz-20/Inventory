import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/db_service.dart';
import 'package:sqflite/sqflite.dart';

final dbServiceProvider = Provider<DBService>((ref) => DBService.instance);

final databaseProvider = FutureProvider<Database>((ref) async {
  final dbService = ref.watch(dbServiceProvider);
  return await dbService.database;
});
