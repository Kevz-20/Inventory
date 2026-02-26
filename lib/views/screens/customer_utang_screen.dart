// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../models/utang_customer_model.dart';
import '../../services/db_service.dart';
import '../widgets/header.dart';

class CustomerUtangScreen extends StatefulWidget {
  const CustomerUtangScreen({super.key});

  @override
  State<CustomerUtangScreen> createState() => _CustomerUtangScreenState();
}

class _CustomerUtangScreenState extends State<CustomerUtangScreen>
    with WidgetsBindingObserver {
  final currencyFormat = NumberFormat("#,##0.00", "en_PH");
  final searchController = TextEditingController();

  List<UtangCustomer> utangan = [];
  List<UtangCustomer> filteredUtangan = [];

  bool _loadedOnce = false;

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  int _daysUntil(DateTime dueDate) {
    final today = _dateOnly(DateTime.now());
    final due = _dateOnly(dueDate);
    return due.difference(today).inDays;
  }

  bool _isOverdue(DateTime dueDate) => _daysUntil(dueDate) < 0;

  String _buildDueStatusText(DateTime dueDate) {
    final daysLeft = _daysUntil(dueDate);
    final formattedDueDate = DateFormat('MMM dd, yyyy').format(dueDate);

    if (daysLeft < 0) return "Overdue • Due: $formattedDueDate";
    if (daysLeft == 0) return "Due today • Due: $formattedDueDate";
    return "Due: $formattedDueDate • $daysLeft day${daysLeft != 1 ? 's' : ''} left";
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedOnce) return;
    _loadedOnce = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    await fetchUtangan();
  }

  Future<void> fetchUtangan() async {
    final db = await DBService.instance.database;

    const sql = '''
  SELECT
    c.id,
    c.first_name,
    c.middle_name,
    c.last_name,
    c.municipality,
    c.barangay,
    c.phone_number,
    MAX(0, COALESCE(sc.total_amount, 0) - COALESCE(cp.total_paid, 0)) AS total_amount,
    sc.min_due_date AS due_date
  FROM customer c
  LEFT JOIN (
    SELECT
      customer_id,
      SUM(amount) AS total_amount,
      MIN(due_date) AS min_due_date
    FROM sales_credit
    GROUP BY customer_id
  ) sc ON sc.customer_id = c.id
  LEFT JOIN (
    SELECT
      customer_id,
      SUM(amount) AS total_paid
    FROM customer_payment
    GROUP BY customer_id
  ) cp ON cp.customer_id = c.id
  ORDER BY total_amount DESC, c.last_name ASC, c.first_name ASC
''';

    try {
      debugPrint('fetchUtangan SQL:\n$sql');
      final result = await db.rawQuery(sql);

      if (!mounted) return;
      setState(() {
        utangan = result.map((e) => UtangCustomer.fromMap(e)).toList();
        filteredUtangan = List.from(utangan);
      });
    } catch (e) {
      debugPrint('fetchUtangan ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('fetchUtangan failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void filterUtangan(String query) {
    if (query.isEmpty) {
      filteredUtangan = List.from(utangan);
    } else {
      filteredUtangan = utangan
          .where((u) => u.fullName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        title: 'Customer Utang',
        showBackButton: true,
        action: IconButton(
          tooltip: 'Add Customer',
          onPressed: () async {
            final result = await context.push<bool>('/new_customer');
            if (result == true) {
              await fetchUtangan();
            }
          },
          icon: const Icon(
            Icons.person_add_alt_1,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          _buildCustomerPage(),
        ],
      ),
    );
  }

  Widget _buildCustomerPage() {
    return Expanded(
      child: Column(
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
                onChanged: filterUtangan,
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
                    itemCount: filteredUtangan.length,
                    itemBuilder: (context, index) {
                      final item = filteredUtangan[index];
                      return _buildCustomerCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(UtangCustomer item) {
    return GestureDetector(
      onTap: () async {
        await GoRouter.of(context).push('/utang_summary', extra: item);
        _refreshData();
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₱${currencyFormat.format(item.totalAmount)}",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.dueDate != null && item.totalAmount <= 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Paid",
                            style: TextStyle(
                              color: Colors.green[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (item.municipality != null && item.municipality!.isNotEmpty)
                Text(
                  item.municipality!,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              const SizedBox(height: 2),
              if (item.barangay != null && item.barangay!.isNotEmpty)
                Text(
                  "Barangay ${item.barangay!}",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.phoneNumber != null && item.phoneNumber!.isNotEmpty)
                    Text(
                      item.phoneNumber!,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  if (item.dueDate != null && item.totalAmount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _isOverdue(item.dueDate!)
                            ? Colors.red[100]
                            : Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _buildDueStatusText(item.dueDate!),
                        style: TextStyle(
                          color: _isOverdue(item.dueDate!)
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
  }
}