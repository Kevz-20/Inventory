import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // ✅ import intl for formatting
import '../../core/app_colors.dart';
import '../../models/payable_model.dart';
import '../../repositories/payable_repository.dart';
import '../widgets/header.dart';
import '../../services/db_service.dart';
import 'add_utang_screen.dart';

final TextEditingController searchController = TextEditingController();
List<UtangCustomer> allUtangan = [];
List<UtangCustomer> visibleUtangan = [];

// ============================================================
// MODEL
// ============================================================
class UtangCustomer {
  final int id;
  final String firstName;
  final String? middleName;
  final String? lastName;
  final String? municipality;
  final String? barangay; // 🔥 NEW
  final String? phoneNumber;
  final double totalAmount;
  final String? dueDate; // NEW

  UtangCustomer({
    required this.id,
    required this.firstName,
    this.middleName,
    this.lastName,
    this.municipality,
    this.barangay, // 🔥 NEW
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
      municipality: map['municipality'],
      barangay: map['barangay'],
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

  // ====== Owner Payables ======
  List<Payable> ownerPayables = []; // all payables
  List<Payable> filteredOwnerPayables = []; // filtered payables

  // ✅ Number format for thousands separator
  final currencyFormat = NumberFormat("#,##0.00", "en_PH");

  @override
  void initState() {
    super.initState();
    fetchUtangan();
    fetchOwnerPayables(); // ✅ fetch owner payables
  }

  // ============================================================
  // FETCH ALL CUSTOMER UTANG
  // ============================================================
  Future<void> fetchUtangan() async {
    final db = await DBService.instance.database;

    final result = await db.rawQuery('''
    SELECT c.id, c.first_name, c.middle_name, c.last_name,
          c.municipality,
          c.barangay,  
          c.phone_number,
          SUM(sc.amount) as total_amount,
          MIN(sc.due_date) as due_date
    FROM sales_credit sc
    INNER JOIN customer c ON c.id = sc.customer_id
    GROUP BY c.id
    ORDER BY total_amount DESC
  ''');

    final data = result.map((e) => UtangCustomer.fromMap(e)).toList();

    setState(() {
      utangan = data; // preserved (optional legacy)
      allUtangan = data; // source of truth
      visibleUtangan = data; // filtered list
    });
  }

  void filterUtangan(String query) {
    final q = query.toLowerCase().trim();

    if (q.isEmpty) {
      visibleUtangan = List.from(allUtangan);
    } else {
      visibleUtangan = allUtangan
          .where((u) => u.fullName.toLowerCase().contains(q))
          .toList();
    }

    setState(() {});
  }

  // ============================================================
  // FETCH OWNER PAYABLES FROM DB
  // ============================================================
  Future<void> fetchOwnerPayables() async {
    final payables = await PayableRepository().getAllPayables();

    setState(() {
      ownerPayables = payables;
      applyOwnerFilter(selectedFilter); // apply default filter
    });
  }

  // ============================================================
  // APPLY FILTER FUNCTION
  // ============================================================
  void applyOwnerFilter(int filterIndex) {
    selectedFilter = filterIndex;

    switch (filterIndex) {
      case 0: // Tanan
        filteredOwnerPayables = List.from(ownerPayables);
        break;
      case 1: // Overdue
        filteredOwnerPayables = ownerPayables
            .where(
              (p) =>
                  !p.isPaid &&
                  p.dueDate != null &&
                  DateTime.tryParse(p.dueDate!) != null &&
                  DateTime.parse(p.dueDate!).isBefore(DateTime.now()),
            )
            .toList();
        break;
      case 2: // Nabayran (Paid)
        filteredOwnerPayables = ownerPayables.where((p) => p.isPaid).toList();
        break;
      default:
        filteredOwnerPayables = List.from(ownerPayables);
    }
    setState(() {});
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
              height: 60,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Stack(
                children: [
                  // Sliding green background
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: selectedTab == 0
                        ? 0
                        : MediaQuery.of(context).size.width / 2 - 30,
                    right: selectedTab == 0
                        ? MediaQuery.of(context).size.width / 2 - 30
                        : 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C4B3E),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  // Toggle texts
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedTab = 0),
                          child: Center(
                            child: Text(
                              "Customer Utang",
                              style: TextStyle(
                                fontSize: 16,
                                color: selectedTab == 0
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedTab = 1),
                          child: Center(
                            child: Text(
                              "Owner Utang",
                              style: TextStyle(
                                fontSize: 16,
                                color: selectedTab == 1
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          // Page content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: Offset(selectedTab == 0 ? 1 : -1, 0),
                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(position: offsetAnimation, child: child);
              },
              child: selectedTab == 0 ? customerPage() : ownerPage(),
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
            child: TextField(
              controller: searchController,
              onChanged: filterUtangan,
              decoration: const InputDecoration(
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
          child: visibleUtangan.isEmpty
              ? const Center(
                  child: Text(
                    "Walay utangan",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: visibleUtangan.length,
                  itemBuilder: (context, index) {
                    final item = visibleUtangan[index];

                    return GestureDetector(
                      onTap: () => GoRouter.of(
                        context,
                      ).push('/utang_summary', extra: item),
                      child: Card(
                        color: Colors.white,
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
                                    "₱${currencyFormat.format(item.totalAmount)}",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
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
                              if (item.barangay != null &&
                                  item.barangay!.isNotEmpty)
                                Text(
                                  "Barangay ${item.barangay!}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              const SizedBox(height: 2),
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
    Color statusColor(String status) {
      switch (status) {
        case 'Overdue':
          return Colors.red.shade100;
        case 'Due Soon':
          return Colors.orange.shade100;
        case 'Paid':
          return Colors.green.shade100;
        default:
          return Colors.grey.shade200;
      }
    }

    Color statusTextColor(String status) {
      switch (status) {
        case 'Overdue':
          return Colors.red.shade800;
        case 'Due Soon':
          return Colors.orange.shade800;
        case 'Paid':
          return Colors.green.shade800;
        default:
          return Colors.grey.shade800;
      }
    }

    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 20),
            // FILTER BUTTONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  filterButton(0, "Tanan"),
                  filterButton(1, "Overdue"),
                  filterButton(2, "Nabayran"),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // LIST OF OWNER UTANG
            Expanded(
              child: filteredOwnerPayables.isEmpty
                  ? const Center(
                      child: Text(
                        "Walay bayranan",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: filteredOwnerPayables.length,
                      itemBuilder: (context, index) {
                        final item = filteredOwnerPayables[index];

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Card(
                            color: Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // ITEM NAME
                                        Text(
                                          item.item,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        // ✅ formatted amount
                                        Text(
                                          "₱${currencyFormat.format(item.amount)}",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        // DUE DATE
                                        Text(
                                          "Due: ${item.dueDate ?? '-'}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        // INSTALLMENT TYPE
                                        Text(
                                          item.isInstallment
                                              ? "Installment"
                                              : "Non-installment",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: item.isInstallment
                                                ? Colors.orange.shade800
                                                : Colors.blue.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor(item.status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      item.status,
                                      style: TextStyle(
                                        color: statusTextColor(item.status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 100),
          ],
        ),
        // ADD BUTTON
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddUtangPage()),
                );

                if (result == true) {
                  fetchOwnerPayables(); // 🔥 reload owner utang
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                "Pagdugang og Bayronon",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTER BUTTON OVERRIDE
  // ============================================================
  Widget filterButton(int index, String text) {
    bool active = selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => applyOwnerFilter(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
