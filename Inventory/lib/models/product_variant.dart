import 'product_selling_option.dart';
import 'product_unit_conversion.dart';

/// Unified variant model replacing the separate ProductUnitConversion
/// (wholesale) and ProductSellingOption (retail) models.
///
/// variantType values:
///   'conversion' – used only for stock-in purchase-unit math
///   'sale'       – shown only as a quick-sale button at checkout
///   'both'       – used for both (default for new variants)
class ProductVariant {
  final int? id;
  final int? productId;

  /// Canonical unit name used for conversion math (e.g. 'kilo', 'gallon').
  final String unitName;

  /// Display label shown on chips / quick-sale buttons.
  /// Usually equals unitName; can differ for bundles ('3 pcs', '½ liter').
  final String label;

  /// How many base units this variant equals.
  /// Nullable: null means per-piece estimate (e.g. onion by gram/piece).
  final int? baseQuantity;

  /// Optional sell price.  Required when variantType includes 'sale'.
  final double? sellPrice;

  /// 'conversion' | 'sale' | 'both'
  final String variantType;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductVariant({
    this.id,
    this.productId,
    required this.unitName,
    required this.label,
    this.baseQuantity,
    this.sellPrice,
    this.variantType = 'both',
    this.createdAt,
    this.updatedAt,
  });

  // ─── type helpers ───────────────────────────────────────────────────────────

  bool get isConversion =>
      variantType == 'conversion' || variantType == 'both';

  bool get isSale => variantType == 'sale' || variantType == 'both';

  // ─── backward-compat converters ─────────────────────────────────────────────

  ProductUnitConversion toUnitConversion() {
    return ProductUnitConversion(
      id: id,
      productId: productId,
      unitName: unitName,
      baseQuantity: baseQuantity ?? 0,
      sellPrice: sellPrice,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  ProductSellingOption toSellingOption() {
    return ProductSellingOption(
      id: id,
      productId: productId,
      label: label,
      mode: 'preset',
      unitName: unitName,
      baseQuantity: baseQuantity,
      price: sellPrice ?? 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'unit_name': unitName,
      'label': label,
      'base_quantity': baseQuantity,
      'sell_price': sellPrice,
      'variant_type': variantType,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] as int?,
      productId: map['product_id'] as int?,
      unitName: (map['unit_name'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      baseQuantity: (map['base_quantity'] as num?)?.toInt(),
      sellPrice: (map['sell_price'] as num?)?.toDouble(),
      variantType: (map['variant_type'] ?? 'both').toString(),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'].toString()),
    );
  }

  ProductVariant copyWith({
    int? id,
    int? productId,
    String? unitName,
    String? label,
    int? baseQuantity,
    double? sellPrice,
    String? variantType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      unitName: unitName ?? this.unitName,
      label: label ?? this.label,
      baseQuantity: baseQuantity ?? this.baseQuantity,
      sellPrice: sellPrice ?? this.sellPrice,
      variantType: variantType ?? this.variantType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
