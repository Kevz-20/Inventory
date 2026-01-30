import 'package:sqflite/sqlite_api.dart';
import '../models/fixed_asset_model.dart';
import 'account_repository.dart';

class FixedAssetRepository {
  final Database database;
  final AccountRepository accountRepository;

  FixedAssetRepository(this.database) : accountRepository = AccountRepository();

  Future<int> insertAsset(FixedAssetModel asset) async {
    final accountId = await accountRepository.getAccountId();
    final map = asset.toMap();
    map['account_id'] = accountId;
    return await database.insert('fixed_asset', map);
  }

  Future<List<FixedAssetModel>> getAllAssets() async {
    final result = await database.query('fixed_asset');
    return result.map((e) => FixedAssetModel.fromMap(e)).toList();
  }
}
