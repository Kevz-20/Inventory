class FixedAssetModel {
  int? id;
  int? accountId;
  String name;
  String category;
  double cost;
  DateTime dateAcquired;
  double accumulatedDepreciation;
  DateTime createdAt;

  FixedAssetModel({
    this.id,
    this.accountId,
    required this.name,
    this.category = '',
    required this.cost,
    DateTime? dateAcquired,
    this.accumulatedDepreciation = 0,
    DateTime? createdAt,
  })  : dateAcquired = dateAcquired ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  /// Convert model to map for DB insertion/update
  Map<String, Object?> toMap({bool includeId = false}) {
    final map = <String, Object?>{
      'name': name,
      'category': category,
      'cost': cost,
      'date_acquired': dateAcquired.toIso8601String(),
      'accumulated_depreciation': accumulatedDepreciation,
      'created_at': createdAt.toIso8601String(),
    };

    if (accountId != null) {
      map['account_id'] = accountId;
    }

    if (includeId && id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Create a FixedAssetModel from a database map
  factory FixedAssetModel.fromMap(Map<String, dynamic> map) {
    return FixedAssetModel(
      id: map['id'] as int?,
      accountId: map['account_id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String? ?? '',
      cost: (map['cost'] as num).toDouble(),
      dateAcquired: map['date_acquired'] != null
          ? DateTime.tryParse(map['date_acquired']) ?? DateTime.now()
          : DateTime.now(),
      accumulatedDepreciation: map['accumulated_depreciation'] != null
          ? (map['accumulated_depreciation'] as num).toDouble()
          : 0,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
