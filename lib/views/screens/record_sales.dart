import 'package:flutter/material.dart';
import 'package:dswd_slp/core/app_colors.dart';
import '../widgets/header.dart';

class RecordSalesScreen extends StatefulWidget {
  const RecordSalesScreen({super.key});

  @override
  RecordSalesScreenState createState() => RecordSalesScreenState();
}

class RecordSalesScreenState extends State<RecordSalesScreen> {
  bool isCash = true;
  int total = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Halin', showBackButton: true),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cashUtangSwitch(),
                  const SizedBox(height: 16),
                  isCash ? _cashList() : _utangList(),
                ],
              ),
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _cashUtangSwitch() => Row(
    children: [
      _switchButton("Cash", isCash, () => setState(() => isCash = true)),
      const SizedBox(width: 10),
      _switchButton("Utang", !isCash, () => setState(() => isCash = false)),
    ],
  );

  Widget _switchButton(String title, bool active, VoidCallback onTap) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
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

  Widget _cashList() => Column(
    children: [
      _searchBar(),
      const SizedBox(height: 12),
      _categoryChips(),
      const SizedBox(height: 16),
      _productCard("Coke 8Oz", 11, 70, "https://i.imgur.com/0T9QZQH.png"),
      const SizedBox(height: 12),
      _productCard(
        "Piattos 250Grams",
        18,
        54,
        "https://i.imgur.com/8qWsw0k.png",
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
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(14),
    ),
    child: const TextField(
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: "Search products",
        icon: Icon(Icons.search, size: 20),
      ),
    ),
  );

  Widget _categoryChips() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _chip("All", true),
        _chip("Drinks"),
        _chip("Alcohol"),
        _chip("Food"),
        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ],
    ),
  );

  Widget _chip(String label, [bool selected = false]) => Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: selected ? AppColors.primaryLight : Colors.grey[200],
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      label,
      style: TextStyle(color: selected ? AppColors.primary : Colors.black87),
    ),
  );

  Widget _productCard(String name, double price, int stock, String imageUrl) =>
      Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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

  Widget _bottomBar() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
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
            "Total: ₱$total",
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
