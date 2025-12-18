import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../widgets/header.dart';

class UtangScreen extends StatefulWidget {
  const UtangScreen({super.key});

  @override
  State<UtangScreen> createState() => _UtangScreenState();
}

class _UtangScreenState extends State<UtangScreen> {
  int selectedTab = 0; // 0 = Customer, 1 = Owner
  int selectedFilter = 0; // 0 = Tanan, 1 = Overdue, 2 = Nabayran
  int navIndex = 1; // History highlighted

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,

      appBar: const AppHeader(title: 'Utang', showBackButton: true),

      body: Column(
        children: [
          const SizedBox(height: 20),

          /// TOGGLE BUTTONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedTab = 0),
                      child: toggleButton("Customer Utang", selectedTab == 0),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedTab = 1),
                      child: toggleButton("Owner Utang", selectedTab == 1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          /// PAGE CONTENT
          Expanded(
            child: IndexedStack(
              index: selectedTab,
              children: [customerPage(), ownerPage()],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CUSTOMER UTANG PAGE
  // ============================================================
  Widget customerPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Pangalan sa Utangan",
                border: InputBorder.none, // removes main border
                enabledBorder: InputBorder.none, // removes enabled border
                focusedBorder: InputBorder.none, // removes focused border
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 100),

        const Text(
          "Walay utangan",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
        
      ],
    );
  }

  // ============================================================
  // OWNER UTANG PAGE
  // ============================================================
  Widget ownerPage() {
    return Column(
      children: [
        /// MAIN CONTENT
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: smallCard("Overdue", "₱0.00 (0)", true)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: smallCard("Due this Week", "₱0.00 (0)", false),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    filterButton(0, "Tanan"),
                    const SizedBox(width: 12),
                    filterButton(1, "Overdue"),
                    const SizedBox(width: 12),
                    filterButton(2, "Nabayran"),
                  ],
                ),

                const SizedBox(height: 80),

                const Text(
                  "Walay bayranan",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),

        /// ADD BUTTON
        Container(
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          height: 55,
          decoration: BoxDecoration(
            color: const Color(0xFF0C4B3E),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Center(
            child: Text(
              "Pagdugang og Bayronon",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REUSABLE WIDGETS
  // ============================================================
  Widget toggleButton(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF0C4B3E) : Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget smallCard(String title, String value, bool red) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, color: Color(0xff444444)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: red ? Colors.red : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget filterButton(int index, String text) {
    bool active = selectedFilter == index;

    return GestureDetector(
      onTap: () => setState(() => selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0C4B3E) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : Colors.black,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
