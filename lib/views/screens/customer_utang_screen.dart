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

  /// ✅ Short, professional due label
  String _dueLabel(DateTime dueDate) {
    final daysLeft = _daysUntil(dueDate);
    if (daysLeft < 0) return "OVERDUE";
    if (daysLeft == 0) return "DUE TODAY";
    return "$daysLeft DAY${daysLeft == 1 ? "" : "S"} LEFT";
  }

  /// ✅ Keep your detailed text, but shorter
  String _dueSubText(DateTime dueDate) {
    final formattedDueDate = DateFormat('MMM dd, yyyy').format(dueDate);
    return "Due: $formattedDueDate";
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
      final result = await db.rawQuery(sql);

      if (!mounted) return;
      setState(() {
        utangan = result.map((e) => UtangCustomer.fromMap(e)).toList();
        filteredUtangan = List.from(utangan);
      });
    } catch (e) {
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
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [          
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearch(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: utangan.isEmpty
                  ? Center(
                      child: Text(
                        "Walay utangan",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      itemCount: filteredUtangan.length,
                      itemBuilder: (context, index) {
                        final item = filteredUtangan[index];
                        return _buildCustomerCard(item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: filterUtangan,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: Colors.black.withOpacity(0.6)),
          hintText: "Pangalan sa Utangan",
          hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    searchController.clear();
                    filterUtangan('');
                  },
                  icon: Icon(Icons.clear, color: Colors.black.withOpacity(0.5)),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCustomerCard(UtangCustomer item) {
    final hasDebt = item.totalAmount > 0;
    final due = item.dueDate;

    // ✅ NEW: hide status pill for brand-new customers (no transactions)
    final bool hidePill = (item.totalAmount <= 0) && (due == null);

    final bool overdue = due != null && _isOverdue(due);
    final bool dueToday = due != null && _daysUntil(due) == 0;

    final Color pillBg = !hasDebt
        ? Colors.green.withOpacity(0.12)
        : overdue
            ? Colors.red.withOpacity(0.12)
            : dueToday
                ? Colors.orange.withOpacity(0.14)
                : AppColors.primary.withOpacity(0.12);

    final Color pillFg = !hasDebt
        ? Colors.green.shade700
        : overdue
            ? Colors.red.shade700
            : dueToday
                ? Colors.orange.shade800
                : AppColors.primary;

    return GestureDetector(
      onTap: () async {
        await GoRouter.of(context).push('/utang_summary', extra: item);
        _refreshData();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _miniLine(
                    icon: Icons.location_on_outlined,
                    text: _buildLocation(item),
                  ),
                  const SizedBox(height: 2),
                  if (item.phoneNumber != null && item.phoneNumber!.isNotEmpty)
                    _miniLine(
                      icon: Icons.call_outlined,
                      text: item.phoneNumber!,
                    ),
                  if (hasDebt && due != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _dueSubText(due),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.55),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₱${currencyFormat.format(item.totalAmount)}",
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                // ✅ NEW: only show pill when NOT brand-new customer
                if (!hidePill) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: pillBg.withOpacity(0.6)),
                    ),
                    child: Text(
                      !hasDebt
                          ? "PAID"
                          : (due == null ? "NO DUE DATE" : _dueLabel(due)),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: pillFg,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 6),
                Icon(Icons.chevron_right,
                    size: 20, color: Colors.black.withOpacity(0.35)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniLine({required IconData icon, required String text}) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black.withOpacity(0.45)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.8,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.55),
            ),
          ),
        ),
      ],
    );
  }

  String _buildLocation(UtangCustomer item) {
    final parts = <String>[];

    if (item.municipality != null && item.municipality!.trim().isNotEmpty) {
      parts.add(item.municipality!.trim());
    }
    if (item.barangay != null && item.barangay!.trim().isNotEmpty) {
      parts.add("Brgy. ${item.barangay!.trim()}");
    }

    return parts.join(" • ");
  }
}