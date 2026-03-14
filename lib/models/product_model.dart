class ProductModel {
  int? id;
  String? localUuid;
  String? serverId;
  String? syncStatus;
  String? lastSyncedAt;
  String name;
  String category;
  int? categoryId; // ✅ keep this
  double purchasePrice;
  double sellingPrice;
  int quantity;
  String? image;
  DateTime createdAt;
  DateTime updatedAt;

  ProductModel({
    this.id,
    this.localUuid,
    this.serverId,
    this.syncStatus,
    this.lastSyncedAt,
    required this.name,
    required this.category,
    this.categoryId, // ✅ add in constructor
    required this.purchasePrice,
    required this.sellingPrice,
    required this.quantity,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'local_uuid': localUuid,
      'server_id': serverId,
      'sync_status': syncStatus,
      'last_synced_at': lastSyncedAt,
      'name': name,
      'category': category,
      'category_id': categoryId, // ✅ NEW
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'image': image,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      localUuid: map['local_uuid'] as String?,
      serverId: map['server_id'] as String?,
      syncStatus: map['sync_status'] as String?,
      lastSyncedAt: map['last_synced_at'] as String?,
      name: (map['name'] ?? '') as String,
      category: (map['category'] ?? '') as String,
      categoryId: map['category_id'] as int?, // ✅ NEW
      purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as int?) ?? 0,
      image: map['image'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // If you need this for old UI filters, make it safe (optional):
  // int get categoryIndex => 0;
}
