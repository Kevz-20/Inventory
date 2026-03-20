import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/product_model.dart';
import '../../models/product_selling_option.dart';
import '../../models/product_unit_conversion.dart';
import '../../repositories/account_repository.dart';
import '../../repositories/product_category_repository.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/stock_in_repository.dart';
import '../../services/db_service.dart';

import '../widgets/primary_footer_nav.dart';

class ManageInventoryScreen extends StatefulWidget {
  const ManageInventoryScreen({super.key});

  @override
  State<ManageInventoryScreen> createState() => _ManageInventoryScreenState();
}

class _ManageInventoryScreenState extends State<ManageInventoryScreen> {
  static const Color _pageBg = Color(0xFFF0F4FF);
  static const Color _cardBg = Colors.white;
  static const Color _border = Color(0xFFCDD5EE);
  static const Color _textPrimary = Color(0xFF1B3A7A);
  static const Color _textSecondary = Color(0xFF5B6D96);
  static const Color _accentBlue = Color(0xFF2D5BE3);

  final TextEditingController _searchController = TextEditingController();

  late ProductRepository _productRepository;
  late ProductCategoryRepository _categoryRepository;
  late StockInRepository _stockInRepository;

  List<ProductModel> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _init();
    _searchController.addListener(() => setState(() {}));
  }

  Future<void> _init() async {
    final db = await DBService.instance.database;
    _productRepository = ProductRepository(db, AccountRepository());
    _categoryRepository = ProductCategoryRepository(db);
    _stockInRepository = StockInRepository(db);
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _productRepository.getProducts(),
      _categoryRepository.getAllCategories(),
    ]);

    if (!mounted) return;
    setState(() {
      _products = results[0] as List<ProductModel>;
      _categories = results[1] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  List<ProductModel> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _products;
    return _products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
    }).toList();
  }

  String _peso(double value) => 'PHP ${value.toStringAsFixed(2)}';

  bool _isLowStock(ProductModel product) => product.quantity <= 10;

  Future<bool?> _openAdvancedSetupDialog(ProductModel product) async {
    if (product.id == null) return null;

    final baseUnitController = TextEditingController(text: product.baseUnit);
    final conversionNameController = TextEditingController();
    final conversionQtyController = TextEditingController();
    final presetLabelController = TextEditingController();
    final presetQtyController = TextEditingController();
    final presetPriceController = TextEditingController();

    final conversions = (await _stockInRepository.getUnitConversions(product.id!))
        .toList();
    final sellingOptions =
        (await _stockInRepository.getSellingOptions(product.id!)).toList();
    if (!mounted) return null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        var localSaving = false;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            void addConversion() {
              final name = conversionNameController.text.trim();
              final qty = int.tryParse(conversionQtyController.text.trim()) ?? 0;
              if (name.isEmpty || qty <= 0) return;

              setLocalState(() {
                conversions
                  ..removeWhere(
                    (item) => item.unitName.toLowerCase() == name.toLowerCase(),
                  )
                  ..add(ProductUnitConversion(unitName: name, baseQuantity: qty))
                  ..sort((a, b) => b.baseQuantity.compareTo(a.baseQuantity));
                conversionNameController.clear();
                conversionQtyController.clear();
              });
            }

            void addPreset() {
              final label = presetLabelController.text.trim();
              final qty = int.tryParse(presetQtyController.text.trim()) ?? 0;
              final price = double.tryParse(presetPriceController.text.trim()) ?? 0;
              if (label.isEmpty || qty <= 0 || price <= 0) return;

              setLocalState(() {
                sellingOptions
                  ..removeWhere(
                    (item) => item.label.toLowerCase() == label.toLowerCase(),
                  )
                  ..add(
                    ProductSellingOption(
                      label: label,
                      mode: 'preset',
                      unitName: baseUnitController.text.trim().isEmpty
                          ? 'pcs'
                          : baseUnitController.text.trim(),
                      baseQuantity: qty,
                      price: price,
                    ),
                  )
                  ..sort((a, b) {
                    final qtyCompare =
                        (b.baseQuantity ?? 0).compareTo(a.baseQuantity ?? 0);
                    if (qtyCompare != 0) return qtyCompare;
                    return a.label.toLowerCase().compareTo(b.label.toLowerCase());
                  });
                presetLabelController.clear();
                presetQtyController.clear();
                presetPriceController.clear();
              });
            }

            Future<void> saveAdvancedSetup() async {
              final nextBaseUnit = baseUnitController.text.trim();
              if (nextBaseUnit.isEmpty) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Please enter a base unit.')),
                );
                return;
              }

              setLocalState(() => localSaving = true);
              try {
                await _stockInRepository.addBaseUnit(nextBaseUnit);
                await _productRepository.updateProduct(
                  ProductModel(
                    id: product.id,
                    name: product.name,
                    category: product.category,
                    categoryId: product.categoryId,
                    purchasePrice: product.purchasePrice,
                    sellingPrice: product.sellingPrice,
                    quantity: product.quantity,
                    baseUnit: nextBaseUnit,
                    costPerUnit: product.costPerUnit,
                    pricePerUnit: product.pricePerUnit,
                    image: product.image,
                    createdAt: product.createdAt,
                    updatedAt: DateTime.now(),
                  ),
                );

                await _stockInRepository.replaceUnitConversions(
                  product.id!,
                  conversions,
                );
                await _stockInRepository.replaceSellingOptions(
                  product.id!,
                  sellingOptions
                      .map(
                        (option) => option.copyWith(
                          unitName: nextBaseUnit,
                        ),
                      )
                      .toList(),
                );

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, true);
              } finally {
                if (dialogContext.mounted) {
                  setLocalState(() => localSaving = false);
                }
              }
            }

            InputDecoration inputDecoration(
              String label, {
              IconData? icon,
              String? prefixText,
            }) {
              return InputDecoration(
                labelText: label,
                prefixIcon:
                    icon == null ? null : Icon(icon, color: _accentBlue, size: 20),
                prefixText: prefixText,
                prefixStyle: const TextStyle(
                  color: _accentBlue,
                  fontWeight: FontWeight.w800,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FBFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _accentBlue, width: 1.3),
                ),
              );
            }

            Widget sectionTitle(String title, String subtitle) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary,
                    ),
                  ),
                ],
              );
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFEEF4FF),
                                Color(0xFFDCE8FF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: _accentBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Advanced Setup',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: _textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Edit unit conversions and quick sale presets for this product.',
                                style: TextStyle(
                                  fontSize: 12.8,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: localSaving
                              ? null
                              : () {
                                  FocusScope.of(dialogContext).unfocus();
                                  Navigator.pop(dialogContext, false);
                                },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _border),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: _textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: baseUnitController,
                      decoration: inputDecoration(
                        'Base unit',
                        icon: Icons.straighten_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    sectionTitle(
                      'More units',
                      'Example: 1 pack = 50 pcs, 1 dozen = 12 pcs.',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: conversionNameController,
                            decoration: inputDecoration(
                              'Unit name',
                              icon: Icons.folder_open_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: conversionQtyController,
                            keyboardType: TextInputType.number,
                            decoration: inputDecoration(
                              'Equivalent pieces',
                              icon: Icons.adjust_rounded,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: addConversion,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add unit conversion'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0E766E),
                          side: const BorderSide(color: Color(0xFF90D3C7)),
                          backgroundColor: const Color(0xFFF1FBF8),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    if (conversions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: conversions
                            .map(
                              (conversion) => Chip(
                                label: Text(
                                  '${conversion.unitName} = ${conversion.baseQuantity} ${baseUnitController.text.trim().isEmpty ? 'pcs' : baseUnitController.text.trim()}',
                                ),
                                onDeleted: () => setLocalState(
                                  () => conversions.remove(conversion),
                                ),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: _border),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 18),
                    sectionTitle(
                      'Quick sale presets',
                      'Use for prices like 3 pcs = PHP 5 or 1 pack = PHP 70.',
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: presetLabelController,
                      decoration: inputDecoration(
                        'Preset label',
                        icon: Icons.local_offer_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: presetQtyController,
                            keyboardType: TextInputType.number,
                            decoration: inputDecoration(
                              'Pieces to deduct',
                              icon: Icons.inventory_2_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: presetPriceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: inputDecoration(
                              'Sell price',
                              prefixText: 'PHP ',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: addPreset,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add sale preset'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accentBlue,
                          side: const BorderSide(color: Color(0xFFCFE0FF)),
                          backgroundColor: const Color(0xFFF5F8FF),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    if (sellingOptions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sellingOptions
                            .map(
                              (option) => Chip(
                                label: Text(
                                  '${option.label} â€¢ ${option.baseQuantity ?? 0} ${baseUnitController.text.trim().isEmpty ? 'pcs' : baseUnitController.text.trim()} â€¢ ${_peso(option.price)}',
                                ),
                                onDeleted: () => setLocalState(
                                  () => sellingOptions.remove(option),
                                ),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: _border),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: localSaving
                                ? null
                                : () {
                                    FocusScope.of(dialogContext).unfocus();
                                    Navigator.pop(dialogContext, false);
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _textPrimary,
                              backgroundColor: const Color(0xFFF8FBFF),
                              side: const BorderSide(color: _border),
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: localSaving ? null : saveAdvancedSetup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentBlue,
                              disabledBackgroundColor: const Color(0xFFAFC6FF),
                              minimumSize: const Size.fromHeight(48),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: localSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save Setup',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true) {
      await _loadData();
      if (!mounted) return saved;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Advanced setup updated successfully.')),
      );
    }

    return saved;
  }

  Future<void> _openEditDialog(ProductModel product) async {
    final nameController = TextEditingController(text: product.name);
    final purchaseController = TextEditingController(
      text: product.purchasePrice.toStringAsFixed(
        product.purchasePrice % 1 == 0 ? 0 : 2,
      ),
    );
    final sellingController = TextEditingController(
      text: product.sellingPrice.toStringAsFixed(
        product.sellingPrice % 1 == 0 ? 0 : 2,
      ),
    );
    final quantityController = TextEditingController(
      text: product.quantity.toString(),
    );

    String? selectedCategory = product.category.isNotEmpty
        ? product.category
        : (_categories.isNotEmpty ? _categories.first['name'] as String : null);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            InputDecoration inputDecoration(
              String label, {
              IconData? icon,
              String? prefixText,
            }) {
              return InputDecoration(
                labelText: label,
                prefixIcon: icon == null
                    ? null
                    : Icon(icon, color: _accentBlue),
                prefixText: prefixText,
                prefixStyle: const TextStyle(
                  color: _accentBlue,
                  fontWeight: FontWeight.w800,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FBFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _accentBlue, width: 1.3),
                ),
              );
            }

            Future<void> saveChanges() async {
              final name = nameController.text.trim();
              final purchase = double.tryParse(purchaseController.text.trim());
              final selling = double.tryParse(sellingController.text.trim());
              final quantity = int.tryParse(quantityController.text.trim());

              if (name.isEmpty ||
                  selectedCategory == null ||
                  purchase == null ||
                  selling == null ||
                  quantity == null ||
                  purchase <= 0 ||
                  selling <= 0 ||
                  quantity < 0) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid product details.'),
                  ),
                );
                return;
              }

              if (!mounted) return;
              setState(() => _saving = true);
              try {
                final matchedCategory = _categories.firstWhere(
                  (category) => category['name'] == selectedCategory,
                  orElse: () => <String, dynamic>{},
                );

                final isPieceBased = product.baseUnit.toLowerCase() == 'pcs';

                await _productRepository.updateProduct(
                  ProductModel(
                    id: product.id,
                    name: name,
                    category: selectedCategory!,
                    categoryId: matchedCategory['id'] as int?,
                    purchasePrice: purchase,
                    sellingPrice: selling,
                    quantity: quantity,
                    baseUnit: product.baseUnit,
                    costPerUnit: isPieceBased ? purchase : product.costPerUnit,
                    pricePerUnit: isPieceBased ? selling : product.pricePerUnit,
                    image: product.image,
                    createdAt: product.createdAt,
                    updatedAt: DateTime.now(),
                  ),
                );

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, true);
              } finally {
                if (mounted) {
                  setState(() => _saving = false);
                }
              }
            }

            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFEEF4FF),
                                Color(0xFFDCE8FF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: _accentBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Edit Product',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Update the same product details you entered from stock-in.',
                                style: TextStyle(
                                  fontSize: 12.8,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary.withValues(alpha: 0.92),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _saving
                              ? null
                              : () {
                                  FocusScope.of(dialogContext).unfocus();
                                  Navigator.pop(dialogContext, false);
                                },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _border),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: _textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _dialogInfoPill(
                          icon: Icons.straighten_rounded,
                          label: 'Base unit: ${product.baseUnit}',
                        ),
                        _dialogInfoPill(
                          icon: Icons.sell_rounded,
                          label: 'Per unit: ${_peso(product.pricePerUnit)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: nameController,
                      decoration: inputDecoration(
                        'Product Name',
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: inputDecoration(
                        'Category',
                        icon: Icons.category_rounded,
                      ),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: category['name'] as String,
                              child: Text(category['name'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setLocalState(() => selectedCategory = value),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: purchaseController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: inputDecoration(
                              'Purchase Price',
                              prefixText: 'PHP ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: sellingController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: inputDecoration(
                              'Selling Price',
                              prefixText: 'PHP ',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: inputDecoration(
                        'Stock Quantity',
                        icon: Icons.layers_outlined,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: _accentBlue,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              product.baseUnit.toLowerCase() == 'pcs'
                                  ? 'This will update the same product record from stock-in.'
                                  : 'Advanced unit setup stays preserved here. This editor updates the main product details only.',
                              style: const TextStyle(
                                fontSize: 12.6,
                                fontWeight: FontWeight.w600,
                                color: _textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _saving
                            ? null
                            : () async {
                                final savedAdvanced =
                                    await _openAdvancedSetupDialog(product);
                                if (savedAdvanced == true &&
                                    dialogContext.mounted) {
                                  Navigator.pop(dialogContext, true);
                                }
                              },
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('Advanced setup'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accentBlue,
                          side: const BorderSide(color: Color(0xFFCFE0FF)),
                          backgroundColor: const Color(0xFFF5F8FF),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () {
                                    FocusScope.of(dialogContext).unfocus();
                                    Navigator.pop(dialogContext, false);
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _textPrimary,
                              backgroundColor: const Color(0xFFF8FBFF),
                              side: const BorderSide(color: _border),
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving
                                ? null
                                : () {
                                    FocusScope.of(dialogContext).unfocus();
                                    saveChanges();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentBlue,
                              disabledBackgroundColor: const Color(0xFFAFC6FF),
                              minimumSize: const Size.fromHeight(48),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully.')),
      );
    }
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || product.id == null) return;

    await _productRepository.deleteProduct(product.id!);
    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Product deleted.')));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Image.asset(
            'lib/assets/arrowleft.png',
            width: 22,
            height: 22,
            fit: BoxFit.contain,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Manage Inventory',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFCDD5EE)),
        ),
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search product or category',
                              hintStyle: const TextStyle(
                                color: _textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: _accentBlue,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: _border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: _border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: _accentBlue),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filteredProducts.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No products found.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: _filteredProducts.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                final isLowStock = _isLowStock(product);
                                return Container(
                                  decoration: BoxDecoration(
                                    color: _cardBg,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: const Color(0xFFD3DDF4),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF8EA1D1,
                                        ).withValues(alpha: 0.18),
                                        blurRadius: 22,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 52,
                                              height: 52,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: isLowStock
                                                      ? const [
                                                          Color(0xFFFFF7DD),
                                                          Color(0xFFFFEDBF),
                                                        ]
                                                      : const [
                                                          Color(0xFFEEF4FF),
                                                          Color(0xFFDCE9FF),
                                                        ],
                                                ),
                                                borderRadius: BorderRadius.circular(18),
                                                border: Border.all(
                                                  color: isLowStock
                                                      ? const Color(0xFFF2D48A)
                                                      : const Color(0xFFCFE0FF),
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.inventory_2_outlined,
                                                color: isLowStock
                                                    ? const Color(0xFFB28704)
                                                    : _accentBlue,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product.name,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w900,
                                                      color: _textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFEFF4FF),
                                                      borderRadius:
                                                          BorderRadius.circular(999),
                                                    ),
                                                        child: Text(
                                                          product.category.isEmpty
                                                              ? 'Uncategorized'
                                                              : product.category,
                                                          style: const TextStyle(
                                                            color: _accentBlue,
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                      ),
                                                  if (isLowStock)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 6,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFFFF6DB),
                                                            borderRadius:
                                                                BorderRadius.circular(999),
                                                          ),
                                                          child: const Text(
                                                            'Low Stock',
                                                            style: TextStyle(
                                                              color: Color(0xFFB28704),
                                                              fontWeight: FontWeight.w700,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF4F7FF),
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(
                                              color: const Color(0xFFD9E3F8),
                                              width: 1.1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: _detailTile(
                                                  'Stock',
                                                  '${product.quantity}',
                                                  valueColor: isLowStock
                                                      ? const Color(0xFFB28704)
                                                      : _textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: _detailTile(
                                                  'Buy',
                                                  _peso(product.purchasePrice),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: _detailTile(
                                                  'Sell',
                                                  _peso(product.sellingPrice),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () =>
                                                    _openEditDialog(product),
                                                icon: const Icon(Icons.edit_outlined),
                                                label: const Text('Edit'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: _accentBlue,
                                                  side: const BorderSide(
                                                    color: Color(0xFFD6E0F6),
                                                  ),
                                                  backgroundColor:
                                                      const Color(0xFFF5F8FF),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(14),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () =>
                                                    _deleteProduct(product),
                                                icon: const Icon(Icons.delete_outline),
                                                label: const Text('Delete'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      const Color(0xFFB84747),
                                                  side: const BorderSide(
                                                    color: Color(0xFFF1CACA),
                                                  ),
                                                  backgroundColor:
                                                      const Color(0xFFFFF4F4),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(14),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ],
      ),
      bottomNavigationBar: const PrimaryFooterNav(
        selectedTab: PrimaryFooterTab.products,
      ),
    );
  }

  Widget _detailTile(String label, String value, {Color valueColor = _textPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDCE5F8),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBAC7E6).withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogInfoPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _accentBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _accentBlue,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
