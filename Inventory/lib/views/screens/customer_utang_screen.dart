// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/utang_customer_model.dart';
import '../../services/db_service.dart';


class CustomerUtangScreen extends StatefulWidget {
  const CustomerUtangScreen({super.key, this.initialCustomerId});

  final int? initialCustomerId;

  @override
  State<CustomerUtangScreen> createState() => _CustomerUtangScreenState();
}

class _CustomerUtangScreenState extends State<CustomerUtangScreen>
    with WidgetsBindingObserver {
  static const Color _pageBg = Color(0xFFF0F4FF);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _cardBorder = Color(0xFFCDD5EE);
  static const Color _titleColor = Color(0xFF1B3A7A);
  static const Color _subtitleColor = Color(0xFF5B6D96);

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

  String _dueLabel(DateTime dueDate) {
    final daysLeft = _daysUntil(dueDate);
    if (daysLeft < 0) return "OVERDUE";
    if (daysLeft == 0) return "DUE TODAY";
    return "$daysLeft DAY${daysLeft == 1 ? "" : "S"} LEFT";
  }

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
        final initialCustomerId = widget.initialCustomerId;
        if (initialCustomerId != null) {
          final match = utangan.where((u) => u.id == initialCustomerId).toList();
          if (match.isNotEmpty) {
            filteredUtangan = match;
            searchController.text = match.first.fullName;
          } else {
            filteredUtangan = [];
          }
        } else {
          filteredUtangan = List.from(utangan);
        }
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

  BoxDecoration _surfaceDecoration(double scale) {
    return BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular((20 * scale).clamp(16, 24)),
      border: Border.all(color: _cardBorder),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF93A4CF).withOpacity(0.14),
          blurRadius: (18 * scale).clamp(14, 24),
          offset: Offset(0, (10 * scale).clamp(8, 14)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final double scale = (w / 390).clamp(0.90, 1.20);
        final double padH = (16 * scale).clamp(14, 22);
        final double topGap = (14 * scale).clamp(10, 18);

        return Scaffold(
          backgroundColor: _pageBg,
          appBar: AppBar(
            backgroundColor: const Color(0xFFF0F4FF),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Image.asset(
                'lib/assets/arrowleft.png',
                width: (22 * scale).clamp(20.0, 26.0),
                height: (22 * scale).clamp(20.0, 26.0),
                fit: BoxFit.contain,
              ),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Customer Utang',
              style: TextStyle(
                color: _titleColor,
                fontWeight: FontWeight.w900,
                fontSize: (20 * scale).clamp(18, 24),
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: const Color(0xFFCDD5EE)),
            ),
            actions: [
              IconButton(
                tooltip: 'Add Customer',
                onPressed: () async {
                  final result = await context.push<bool>('/new_customer');
                  if (result == true) {
                    await fetchUtangan();
                  }
                },
                icon: Icon(
                  Icons.person_add_alt_1_rounded,
                  color: _titleColor,
                  size: (24 * scale).clamp(22, 28),
                ),
              ),
              SizedBox(width: (4 * scale).clamp(2, 6)),
            ],
          ),
          body: Stack(
            children: [
              SafeArea(
                top: false,
                child: Column(
                  children: [
                    SizedBox(height: topGap),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: padH),
                      child: Container(
                        padding: EdgeInsets.all((14 * scale).clamp(12, 18)),
                        decoration: _surfaceDecoration(scale),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSearch(scale: scale),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: (12 * scale).clamp(10, 16)),
                    Expanded(
                      child: utangan.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: padH),
                                child: Text(
                                  'No customer utang yet',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: (15 * scale).clamp(14, 18),
                                    fontWeight: FontWeight.w800,
                                    color: _titleColor,
                                  ),
                                ),
                              ),
                            )
                          : (filteredUtangan.isEmpty
                              ? _emptyState(
                                  scale: scale,
                                  padH: padH,
                                  title: widget.initialCustomerId != null
                                      ? 'Customer not found'
                                      : 'No matching customer',
                                  subtitle: 'Try another name or clear your search.',
                                  icon: Icons.search_off_rounded,
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    padH,
                                    (6 * scale).clamp(4, 10),
                                    padH,
                                    padH,
                                  ),
                                  itemCount: filteredUtangan.length,
                                  itemBuilder: (context, index) {
                                    final item = filteredUtangan[index];
                                    return _buildCustomerCard(
                                      item,
                                      scale: scale,
                                      maxWidth: w,
                                    );
                                  },
                                )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState({
    required double scale,
    required double padH,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padH),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all((18 * scale).clamp(16, 22)),
          decoration: _surfaceDecoration(scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: (36 * scale).clamp(30, 44),
                color: _subtitleColor,
              ),
              SizedBox(height: (10 * scale).clamp(8, 12)),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (15 * scale).clamp(14, 18),
                  fontWeight: FontWeight.w800,
                  color: _titleColor,
                ),
              ),
              SizedBox(height: (4 * scale).clamp(3, 6)),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (12.8 * scale).clamp(11.8, 15),
                  fontWeight: FontWeight.w500,
                  color: _subtitleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch({required double scale}) {
    final double height = (54 * scale).clamp(48, 62);

    return Container(
      height: height,
      decoration: _surfaceDecoration(scale).copyWith(
        borderRadius: BorderRadius.circular((18 * scale).clamp(16, 22)),
      ),
      child: TextField(
        controller: searchController,
        onChanged: filterUtangan,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search,
            color: _titleColor,
            size: (22 * scale).clamp(20, 26),
          ),
          hintText: "Search customer",
          hintStyle: TextStyle(
            color: _subtitleColor.withOpacity(0.75),
            fontSize: (14 * scale).clamp(12.5, 16),
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    searchController.clear();
                    filterUtangan('');
                  },
                  icon: Icon(
                    Icons.clear,
                    color: Colors.black.withOpacity(0.5),
                    size: (20 * scale).clamp(18, 24),
                  ),
                )
              : null,
        ),
        style: TextStyle(
          fontSize: (14.5 * scale).clamp(13, 17),
          fontWeight: FontWeight.w700,
          color: _titleColor,
        ),
      ),
    );
  }

  Widget _buildCustomerCard(
    UtangCustomer item, {
    required double scale,
    required double maxWidth,
  }) {
    final hasDebt = item.totalAmount > 0;
    final due = item.dueDate;
    final bool hidePill = (item.totalAmount <= 0) && (due == null);
    final bool overdue = due != null && _isOverdue(due);
    final bool dueToday = due != null && _daysUntil(due) == 0;

    final Color pillBg = !hasDebt
        ? Colors.green.withOpacity(0.12)
        : overdue
            ? Colors.red.withOpacity(0.12)
            : dueToday
                ? Colors.orange.withOpacity(0.14)
                : const Color(0xFF2B63D3).withOpacity(0.12);

    final Color pillFg = !hasDebt
        ? Colors.green.shade700
        : overdue
            ? Colors.red.shade700
            : dueToday
                ? Colors.orange.shade800
                : const Color(0xFF2B63D3);

    final bool isNarrow = maxWidth < 360;
    final bool isTablet = maxWidth >= 700;
    final double rightColWidth = isTablet
        ? 220
        : isNarrow
            ? 125
            : 150;

    final double avatarSize = (44 * scale).clamp(38, 52);
    final double radius = (18 * scale).clamp(16, 22);
    final double pad = (14 * scale).clamp(12, 18);

    return GestureDetector(
      onTap: () async {
        await GoRouter.of(context).push('/utang_summary', extra: item);
        _refreshData();
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: (6 * scale).clamp(5, 9)),
        padding: EdgeInsets.all(pad),
        decoration: _surfaceDecoration(scale).copyWith(
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -26,
              child: Container(
                width: (110 * scale).clamp(90, 130),
                height: (110 * scale).clamp(90, 130),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEAF2FF).withOpacity(0.85),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEAF2FF), Color(0xFFF6F8FF)],
                    ),
                    borderRadius:
                        BorderRadius.circular((14 * scale).clamp(12, 18)),
                  ),
                  child: Icon(
                    Icons.person,
                    color: const Color(0xFF2B63D3),
                    size: (22 * scale).clamp(20, 28),
                  ),
                ),
                SizedBox(width: (12 * scale).clamp(10, 16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: (16 * scale).clamp(14.5, 20),
                          fontWeight: FontWeight.w900,
                          color: _titleColor,
                        ),
                      ),
                      SizedBox(height: (4 * scale).clamp(3, 6)),
                      _miniLine(
                        icon: Icons.location_on_outlined,
                        text: _buildLocation(item),
                        scale: scale,
                      ),
                      SizedBox(height: (2 * scale).clamp(1, 4)),
                      if (item.phoneNumber != null && item.phoneNumber!.isNotEmpty)
                        _miniLine(
                          icon: Icons.call_outlined,
                          text: item.phoneNumber!,
                          scale: scale,
                        ),
                      if (hasDebt && due != null) ...[
                        SizedBox(height: (6 * scale).clamp(4, 8)),
                        Text(
                          _dueSubText(due),
                          style: TextStyle(
                            fontSize: (12.5 * scale).clamp(11.5, 15),
                            fontWeight: FontWeight.w700,
                            color: _subtitleColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: (10 * scale).clamp(8, 14)),
                SizedBox(
                  width: rightColWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          "â‚±${currencyFormat.format(item.totalAmount)}",
                          style: TextStyle(
                            fontSize: (15.5 * scale).clamp(14, 20),
                            fontWeight: FontWeight.w900,
                            color: _titleColor,
                          ),
                        ),
                      ),
                      if (!hidePill) ...[
                        SizedBox(height: (6 * scale).clamp(4, 8)),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: (10 * scale).clamp(8, 12),
                              vertical: (6 * scale).clamp(5, 8),
                            ),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: pillBg.withOpacity(0.6)),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                !hasDebt
                                    ? "PAID"
                                    : (due == null ? "NO DUE DATE" : _dueLabel(due)),
                                style: TextStyle(
                                  fontSize: (11.5 * scale).clamp(10.5, 14),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: pillFg,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: (6 * scale).clamp(4, 8)),
                      Icon(
                        Icons.chevron_right,
                        size: (20 * scale).clamp(18, 26),
                        color: _subtitleColor.withOpacity(0.8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniLine({
    required IconData icon,
    required String text,
    required double scale,
  }) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          icon,
          size: (16 * scale).clamp(14, 20),
          color: _subtitleColor.withOpacity(0.8),
        ),
        SizedBox(width: (6 * scale).clamp(5, 10)),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: (12.8 * scale).clamp(11.5, 16),
              fontWeight: FontWeight.w600,
              color: _subtitleColor,
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

    return parts.join(" â€¢ ");
  }
}
