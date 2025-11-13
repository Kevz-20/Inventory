import 'package:flutter/material.dart';

class BalanceSheetPage extends StatelessWidget {
  const BalanceSheetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EE), // soft beige background
      appBar: AppBar(
        backgroundColor: const Color(0xFF004D40), // dark green top bar
        title: const Text(
          "Balance Sheet",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        elevation: 4,
      ),

      // body content
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Date Range
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDateCard("Sugod", "Oct 16, 2025"),
                _buildDateCard("Tapos", "Oct 23, 2025"),
              ],
            ),
            const SizedBox(height: 20),

            // Assets Section
            _buildSectionCard(
              title: "Assets",
              items: [
                "Cash on Hand",
                "Cash in Bank",
                "Accounts Receivable",
                "Inventory",
                "Fixed Assets",
              ],
              footer: "Total Assets",
            ),

            const SizedBox(height: 20),

            // Liabilities Section
            _buildSectionCard(
              title: "Liabilities",
              items: ["Accounts Payable"],
              footer: "Total Liabilities",
            ),

            const SizedBox(height: 30),

            // Download Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B1EFF), // violet button
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF4B1EFF),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  shadowColor: Colors.black.withOpacity(0.3),
                  elevation: 4,
                ),
                icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
                label: const Text(
                  "Download Balance Sheet (PDF)",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                onPressed: () {
                  debugPrint("Download Balance Sheet tapped");
                },
              ),
            ),
          ],
        ),
      ),

      // bottom nav bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4B1EFF),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "History",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  // Widget builder for date cards
  Widget _buildDateCard(String label, String date) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF5E6), // light cream
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade400,
            blurRadius: 4,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            date,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Widget builder for section cards
  Widget _buildSectionCard({
    required String title,
    required List<String> items,
    required String footer,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF5E6),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade400,
            blurRadius: 5,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          for (var item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          const Divider(thickness: 1),
          Text(
            footer,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
