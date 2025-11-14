import 'package:dswd_slp/core/app_colors.dart';
import 'package:flutter/material.dart';

import '../widgets/header.dart';

class RecordSalesScreen extends StatefulWidget {
  const RecordSalesScreen({super.key});

  @override
  RecordSalesScreenState createState() => RecordSalesScreenState();
}

class RecordSalesScreenState extends State<RecordSalesScreen> {
  bool isCash = true;
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Halin', showBackButton: true),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: isCash ? _cashUI() : _utangUI(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cashUI() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _cashUtangSwitch(),
      const SizedBox(height: 12),
      _searchBar(),
      const SizedBox(height: 12),
      _categoryChips(),
      const SizedBox(height: 15),
      _productCard(
        imageUrl: "https://i.imgur.com/0T9QZQH.png",
        name: "Coke 8Oz",
        price: 11,
        stock: 70,
      ),
      const SizedBox(height: 15),
      _productCard(
        imageUrl: "https://i.imgur.com/8qWsw0k.png",
        name: "Piattos 250Grams",
        price: 18,
        stock: 54,
      ),
      const SizedBox(height: 20),
      const Text(
        "Total:",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      _mainButton("Record"),
    ],
  );

  Widget _utangUI() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _cashUtangSwitch(),
      const SizedBox(height: 20),
      _dueDateCard(),
      const SizedBox(height: 15),
      _customerInput(),
      const SizedBox(height: 15),
      _customerItem("Drake Kan", 900),
      const SizedBox(height: 10),
      _customerItem("Kiel Fen", 1000),
      const SizedBox(height: 30),
      _mainButton("Padayon sa mga produkto"),
    ],
  );

  Widget _cashUtangSwitch() => Row(
    children: [
      Expanded(
        child: GestureDetector(
          onTap: () => setState(() => isCash = true),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isCash ? const Color(0xff1C6CF6) : const Color(0xffe8dfce),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              "Cash",
              style: TextStyle(
                color: isCash ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: GestureDetector(
          onTap: () => setState(() => isCash = false),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: !isCash
                  ? const Color(0xff1C6CF6)
                  : const Color(0xffe8dfce),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              "Utang",
              style: TextStyle(
                color: !isCash ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _searchBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.black26),
    ),
    child: const TextField(
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: "Search",
        icon: Icon(Icons.search_rounded),
      ),
    ),
  );

  Widget _categoryChips() => Row(
    children: [
      _chip("Tanan", true),
      _chip("Imnonon", false),
      _chip("Alak", false),
      _chip("Pagkaon", false),
      const Icon(Icons.arrow_forward_ios_rounded, size: 18),
    ],
  );

  Widget _chip(String text, bool selected) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
    margin: const EdgeInsets.only(right: 8),
    decoration: BoxDecoration(
      color: selected ? const Color(0xffdce8ff) : const Color(0xffefe9dd),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Text(text),
  );

  Widget _productCard({
    required String imageUrl,
    required String name,
    required double price,
    required int stock,
  }) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Image.network(imageUrl, width: 55),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text("Price: ₱$price"),
              Text("Stock: $stock"),
            ],
          ),
        ),
        Row(
          children: [
            _qtyBtn(Icons.remove),
            const Text(" 0 "),
            _qtyBtn(Icons.add),
          ],
        ),
      ],
    ),
  );

  Widget _qtyBtn(IconData icon) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(50),
      border: Border.all(color: Colors.black26),
    ),
    child: IconButton(onPressed: () {}, icon: Icon(icon, size: 18)),
  );

  Widget _dueDateCard() => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: const [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Due Date"),
              SizedBox(height: 5),
              Text(
                "November 30, 2025",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Icon(Icons.calendar_month, size: 28),
      ],
    ),
  );

  Widget _customerInput() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: const [
        Expanded(
          child: Text("Pangalan sa Customer", style: TextStyle(fontSize: 16)),
        ),
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.blue,
          child: Icon(Icons.add, color: Colors.white),
        ),
      ],
    ),
  );

  Widget _customerItem(String name, double limit) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text("Credit Limit: ₱$limit"),
      ],
    ),
  );

  Widget _mainButton(String text) => ElevatedButton(
    onPressed: () {},
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xff1c6cf6),
      minimumSize: const Size(double.infinity, 55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 20, color: Colors.white),
    ),
  );
}
