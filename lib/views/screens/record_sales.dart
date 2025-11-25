import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dswd_slp/core/app_colors.dart';
import '../../view_models/record_sales_view_model.dart';
import '../widgets/header.dart';

class RecordSalesScreen extends ConsumerStatefulWidget {
  const RecordSalesScreen({super.key});

  @override
  ConsumerState<RecordSalesScreen> createState() => _RecordSalesScreenState();
}

class _RecordSalesScreenState extends ConsumerState<RecordSalesScreen> {
  bool isCash = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salesViewModelProvider).reloadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(salesViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Halin', showBackButton: true),
      body: Column(
        children: [
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _cashUtangSwitch(vm),
                        const SizedBox(height: 16),
                        isCash ? _cashList(vm) : _utangList(),
                      ],
                    ),
                  ),
          ),
          _bottomBar(vm),
        ],
      ),
    );
  }

  Widget _cashUtangSwitch(SalesViewModel vm) => Row(
    children: [
      _switchButton("Cash", isCash, () {
        setState(() => isCash = true);
        vm.reloadProducts();
      }),
      const SizedBox(width: 10),
      _switchButton("Utang", !isCash, () {
        setState(() => isCash = false);
      }),
    ],
  );

  Widget _switchButton(String title, bool active, VoidCallback onTap) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 51),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              title,
              style: TextStyle(
                color: active ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );

  Widget _cashList(SalesViewModel vm) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _searchBar(),
      const SizedBox(height: 12),
      _categoryChips(vm),
      const SizedBox(height: 16),
      if (vm.filteredProducts.isEmpty)
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No products found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        )
      else
        ...vm.filteredProducts.map(
          (p) => _productCard(
            p.name,
            p.sellingPrice,
            p.quantity,
            p.image ?? 'https://i.imgur.com/0T9QZQH.png',
          ),
        ),
    ],
  );

  Widget _utangList() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _dueDateCard(),
      const SizedBox(height: 12),
      _customerInput(),
      const SizedBox(height: 12),
      _customerItem("Drake Kan", 900),
      const SizedBox(height: 8),
      _customerItem("Kiel Fen", 1000),
    ],
  );

  Widget _searchBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 51),
          blurRadius: 2,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: const TextField(
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: "Search products",
        icon: Icon(Icons.search, size: 22, color: Colors.black),
        hintStyle: TextStyle(color: Colors.black),
        contentPadding: EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );

  Widget _categoryChips(SalesViewModel vm) => SizedBox(
    height: 50,
    child: ListView.separated(
      clipBehavior: Clip.none,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 0, right: 8),
      itemCount: SalesViewModel.categories.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final selected = index == vm.selectedCategoryIndex;
        return GestureDetector(
          onTap: () => vm.selectCategory(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 51),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              SalesViewModel.categories[index],
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _productCard(String name, double price, int stock, String imageUrl) =>
      Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 51),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.network(imageUrl, width: 50, height: 50),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "Price: ₱$price",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    "Stock: $stock",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            _quantitySelector(),
          ],
        ),
      );

  Widget _quantitySelector() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[300]!),
      borderRadius: BorderRadius.circular(50),
    ),
    child: Row(
      children: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.remove, size: 18)),
        const Text("0", style: TextStyle(fontWeight: FontWeight.bold)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.add, size: 18)),
      ],
    ),
  );

  Widget _dueDateCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: const [
        Expanded(
          child: Text(
            "Due Date: November 30, 2025",
            style: TextStyle(fontSize: 16),
          ),
        ),
        Icon(Icons.calendar_month, size: 24, color: Colors.grey),
      ],
    ),
  );

  Widget _customerInput() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: const [
        Expanded(child: Text("Customer Name", style: TextStyle(fontSize: 16))),
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.add, size: 18, color: Colors.white),
        ),
      ],
    ),
  );

  Widget _customerItem(String name, double limit) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text("Limit: ₱$limit", style: const TextStyle(color: Colors.grey)),
      ],
    ),
  );

  Widget _bottomBar(SalesViewModel vm) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "Total: ₱${vm.total}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              isCash ? "Record" : "Continue",
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );
}
