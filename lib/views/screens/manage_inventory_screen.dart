import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../models/product_model.dart';
import '../../repositories/account_repository.dart';
import '../../repositories/product_category_repository.dart';
import '../../repositories/product_repository.dart';
import '../../services/db_service.dart';
import '../widgets/header.dart';

class ManageInventoryScreen extends StatefulWidget {
  const ManageInventoryScreen({super.key});

  @override
  State<ManageInventoryScreen> createState() => _ManageInventoryScreenState();
}

class _ManageInventoryScreenState extends State<ManageInventoryScreen> {
  static const Color _pageBg = Color(0xFFF4F8F6);
  static const Color _cardBg = Colors.white;
  static const Color _border = Color(0xFFD9E7E2);
  static const Color _softBg = Color(0xFFF7FBF9);
  static const Color _textPrimary = Color(0xFF123B34);
  static const Color _textSecondary = Color(0xFF58766D);

  final TextEditingController _searchController = TextEditingController();

  late ProductRepository _productRepository;
  late ProductCategoryRepository _categoryRepository;

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

  int get _lowStockCount =>
      _products.where((product) => _isLowStock(product)).length;

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
            return AlertDialog(
              title: const Text('Edit Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
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
                    TextField(
                      controller: purchaseController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Purchase Price',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sellingController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Selling Price',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stock Quantity',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final purchase =
                              double.tryParse(purchaseController.text.trim());
                          final selling =
                              double.tryParse(sellingController.text.trim());
                          final quantity =
                              int.tryParse(quantityController.text.trim());

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
                                content: Text(
                                  'Please enter valid product details.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (!mounted) return;
                          setState(() => _saving = true);
                          try {
                            final matchedCategory = _categories.firstWhere(
                              (category) =>
                                  category['name'] == selectedCategory,
                              orElse: () => <String, dynamic>{},
                            );

                            await _productRepository.updateProduct(
                              ProductModel(
                                id: product.id,
                                name: name,
                                category: selectedCategory!,
                                categoryId: matchedCategory['id'] as int?,
                                purchasePrice: purchase,
                                sellingPrice: selling,
                                quantity: quantity,
                                image: product.image,
                                createdAt: product.createdAt,
                                updatedAt: DateTime.now(),
                              ),
                            );

                            if (!mounted) return;
                            Navigator.pop(dialogContext, true);
                          } finally {
                            if (mounted) {
                              setState(() => _saving = false);
                            }
                          }
                        },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    purchaseController.dispose();
    sellingController.dispose();
    quantityController.dispose();

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

  Future<void> _goToAddProduct() async {
    await context.push('/stockin');
    await _loadData();
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
      appBar: const AppHeader(title: 'Manage Inventory', showBackButton: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.06),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Inventory Overview',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Review products, adjust prices, and update stock.',
                              style: TextStyle(
                                fontSize: 13,
                                color: _textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _summaryChip(
                                    icon: Icons.inventory_2_outlined,
                                    label: 'Products',
                                    value: '${_products.length}',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _summaryChip(
                                    icon: Icons.layers_outlined,
                                    label: 'Categories',
                                    value: '${_categories.length}',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _summaryChip(
                                    icon: Icons.warning_amber_rounded,
                                    label: 'Low Stock',
                                    value: '$_lowStockCount',
                                    accentColor: _lowStockCount > 0
                                        ? const Color(0xFFB28704)
                                        : AppColors.primary,
                                    softColor: _lowStockCount > 0
                                        ? const Color(0xFFFFF6DB)
                                        : _softBg,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search product or category',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: _border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: _border),
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
                              'No products found.\nAdd products first to manage inventory.',
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
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: _cardBg,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _border),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.06),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
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
                                            color: _softBg,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: _border),
                                          ),
                                          child: Icon(
                                            Icons.inventory_2_outlined,
                                            color: _isLowStock(product)
                                                ? const Color(0xFFB28704)
                                                : AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product.name,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                  color: _textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _softBg,
                                                      borderRadius:
                                                          BorderRadius.circular(999),
                                                    ),
                                                    child: Text(
                                                      product.category.isEmpty
                                                          ? 'Uncategorized'
                                                          : product.category,
                                                      style: const TextStyle(
                                                        color: AppColors.primary,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  if (_isLowStock(product))
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFFFFF6DB,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                          999,
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'Low Stock',
                                                        style: TextStyle(
                                                          color: Color(0xFFB28704),
                                                          fontWeight:
                                                              FontWeight.w700,
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
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _detailTile(
                                            'Stock',
                                            '${product.quantity}',
                                            valueColor: _isLowStock(product)
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
                                              foregroundColor:
                                                  AppColors.primary,
                                              side: const BorderSide(
                                                color: _border,
                                              ),
                                              backgroundColor: _softBg,
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
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            label: const Text('Delete'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  const Color(0xFFB84747),
                                              side: const BorderSide(
                                                color: Color(0xFFF0C6C6),
                                              ),
                                              backgroundColor:
                                                  const Color(0xFFFFF5F5),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToAddProduct,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _summaryChip({
    required IconData icon,
    required String label,
    required String value,
    Color accentColor = AppColors.primary,
    Color softColor = _softBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailTile(String label, String value, {Color valueColor = _textPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _softBg,
        borderRadius: BorderRadius.circular(14),
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
}
