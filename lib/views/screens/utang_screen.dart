import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../widgets/header.dart';
import '../../services/db_service.dart';
import 'utang_summary.screen.dart';

// ============================================================
// MODEL
// ============================================================
class UtangCustomer {
  final int id;
  final String firstName;
  final String? middleName;
  final String? lastName;
  final String? municipality;
  final String? phoneNumber;
  final double totalAmount;
  final String? dueDate; // NEW

  UtangCustomer({
    required this.id,
    required this.firstName,
    this.middleName,
    this.lastName,
    this.municipality,
    this.phoneNumber,
    required this.totalAmount,
    this.dueDate,
  });

  String get fullName => [
    firstName,
    middleName,
    lastName,
  ].where((e) => e != null && e.isNotEmpty).join(' ');

  // Compute remaining days
  int get remainingDays {
    if (dueDate == null) return 0;
    final due = DateTime.tryParse(dueDate!);
    if (due == null) return 0;
    return due.difference(DateTime.now()).inDays;
  }

  factory UtangCustomer.fromMap(Map<String, dynamic> map) {
    return UtangCustomer(
      id: map['id'],
      firstName: map['first_name'],
      middleName: map['middle_name'],
      lastName: map['last_name'],
      phoneNumber: map['phone_number'],
      totalAmount: map['total_amount']?.toDouble() ?? 0.0,
      dueDate: map['due_date'], // NEW
    );
  }
}

// ============================================================
// SCREEN
// ============================================================
class UtangScreen extends StatefulWidget {
  const UtangScreen({super.key});

  @override
  State<UtangScreen> createState() => _UtangScreenState();
}

class _UtangScreenState extends State<UtangScreen> {
  int selectedTab = 0;
  int selectedFilter = 0;
  List<UtangCustomer> utangan = [];

  @override
  void initState() {
    super.initState();
    fetchUtangan();
  }

  // ============================================================
  // FETCH ALL UTANG (no account filter)
  // ============================================================
  Future<void> fetchUtangan() async {
    final db = await DBService.instance.database;

    final result = await db.rawQuery('''
      SELECT c.id, c.first_name, c.middle_name, c.last_name,
            c.municipality,
            c.phone_number,
            SUM(sc.amount) as total_amount,
            MIN(sc.due_date) as due_date -- ✅ nearest due date
      FROM sales_credit sc
      INNER JOIN customer c ON c.id = sc.customer_id
      GROUP BY c.id
      ORDER BY total_amount DESC
    ''');

    setState(() {
      utangan = result.map((e) => UtangCustomer.fromMap(e)).toList();
    });
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(title: 'Utang', showBackButton: true),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Toggle buttons
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
          // Page content
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
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: utangan.isEmpty
              ? const Center(
                  child: Text(
                    "Walay utangan",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: utangan.length,
                  itemBuilder: (context, index) {
                    final item = utangan[index];
                    return GestureDetector(
                      onTap: () {
                        // Navigate to summary page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UtangSummaryPage(customer: item),
                          ),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name + Remaining Credit
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.fullName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "₱${item.totalAmount.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Municipality
                              if (item.municipality != null &&
                                  item.municipality!.isNotEmpty)
                                Text(
                                  item.municipality!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              // Phone number + Remaining Days
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (item.phoneNumber != null &&
                                      item.phoneNumber!.isNotEmpty)
                                    Text(
                                      item.phoneNumber!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  if (item.dueDate != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.remainingDays <= 0
                                            ? Colors.red[100]
                                            : Colors.green[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "${item.remainingDays} day${item.remainingDays != 1 ? 's' : ''} left",
                                        style: TextStyle(
                                          color: item.remainingDays <= 0
                                              ? Colors.red
                                              : Colors.green[800],
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
