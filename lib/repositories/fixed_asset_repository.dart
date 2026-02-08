import 'package:sqflite/sqlite_api.dart';
import '../models/fixed_asset_model.dart';

class FixedAssetRepository {
  final Database database;

  FixedAssetRepository(this.database);

  /// ---------------- INSERT ASSET ----------------
  /// Inserts a new asset and records who added it
  Future<int> insertAsset(FixedAssetModel asset, {required String addedBy}) async {
    final map = asset.toMap();
    map['added_by'] = addedBy; // track who added it
    map['created_at'] = asset.createdAt.toIso8601String();
    return await database.insert('fixed_asset', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// ---------------- GET ALL ASSETS ----------------
  /// Fetch all assets (shared for all users)
  Future<List<FixedAssetModel>> getAllAssets() async {
    final result = await database.query(
      'fixed_asset',
      orderBy: 'created_at DESC',
    );
    return result.map((e) => FixedAssetModel.fromMap(e)).toList();
  }

  /// ---------------- GET SINGLE ASSET ----------------
  Future<FixedAssetModel?> getAssetById(int id) async {
    final result = await database.query(
      'fixed_asset',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return FixedAssetModel.fromMap(result.first);
  }

  /// ---------------- UPDATE ASSET ----------------
  /// Updates an asset, optionally tracking who updated it
  Future<int> updateAsset(FixedAssetModel asset, {String? updatedBy}) async {
    final map = asset.toMap();
    if (updatedBy != null) map['updated_by'] = updatedBy;
    map['updated_at'] = DateTime.now().toIso8601String();
    return await database.update(
      'fixed_asset',
      map,
      where: 'id = ?',
      whereArgs: [asset.id],
    );
  }

  /// ---------------- DELETE ASSET ----------------
  /// Deletes an asset by ID (all users can see/remove)
  Future<int> deleteAsset(int id) async {
    return await database.delete(
      'fixed_asset',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
