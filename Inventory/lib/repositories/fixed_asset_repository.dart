import 'package:sqflite/sqlite_api.dart';
import '../models/fixed_asset_model.dart';
import '../services/audit_log_service.dart';

class FixedAssetRepository {
  final Database database;

  FixedAssetRepository(this.database);

  /// ---------------- INSERT ASSET ----------------
  /// Inserts a new asset and records who added it
  Future<int> insertAsset(FixedAssetModel asset, {required String addedBy}) async {
    final map = asset.toMap();
    map['added_by'] = addedBy; // track who added it
    map['created_at'] = asset.createdAt.toIso8601String();
    map['updated_at'] = asset.createdAt.toIso8601String();
    map['sync_status'] = 'pending';
    map['last_synced_at'] = null;
    map['is_deleted'] = 0;
    final assetId = await database.insert(
      'fixed_asset',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await AuditLogService.instance.log(
      module: 'fixed_asset',
      tableName: 'fixed_asset',
      recordId: assetId.toString(),
      action: 'create',
      newValue: map,
    );
    return assetId;
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
    final previous = asset.id == null ? null : await getAssetById(asset.id!);
    final map = asset.toMap();
    if (updatedBy != null) map['updated_by'] = updatedBy;
    map['updated_at'] = DateTime.now().toIso8601String();
    map['sync_status'] = 'pending';
    map['last_synced_at'] = null;
    final updated = await database.update(
      'fixed_asset',
      map,
      where: 'id = ?',
      whereArgs: [asset.id],
    );
    if (updated > 0) {
      await AuditLogService.instance.log(
        module: 'fixed_asset',
        tableName: 'fixed_asset',
        recordId: asset.id?.toString(),
        action: 'update',
        oldValue: previous?.toMap(),
        newValue: map,
      );
    }
    return updated;
  }

  /// ---------------- DELETE ASSET ----------------
  /// Deletes an asset by ID (all users can see/remove)
  Future<int> deleteAsset(int id) async {
    final previous = await getAssetById(id);
    final deleted = await database.delete(
      'fixed_asset',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deleted > 0) {
      await AuditLogService.instance.log(
        module: 'fixed_asset',
        tableName: 'fixed_asset',
        recordId: id.toString(),
        action: 'delete',
        oldValue: previous?.toMap(),
      );
    }
    return deleted;
  }
}
