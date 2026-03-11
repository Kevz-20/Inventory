// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../models/utang_customer_model.dart';
import '../../services/db_service.dart';

class UtangCalendarCard extends StatefulWidget {
  const UtangCalendarCard({
    super.key,
    required this.utangList,
    required this.totalUtang,
  });

  final List<Map<String, dynamic>> utangList;
  final double totalUtang;

  @override
  State<UtangCalendarCard> createState() => _UtangCalendarCardState();
}

class _UtangCalendarCardState extends State<UtangCalendarCard> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;
  late Map<String, List<Map<String, dynamic>>> _byDate;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _buildIndex();
  }

  @override
  void didUpdateWidget(UtangCalendarCard old) {
    super.didUpdateWidget(old);
    _buildIndex();
  }

  void _buildIndex() {
    _byDate = {};
    for (final e in widget.utangList) {
      final raw = e['due_date'] as String? ?? '';
      if (raw.isEmpty) continue;
      try {
        final dt = DateTime.parse(raw);
        final key = _dayKey(dt);
        (_byDate[key] ??= []).add(e);
      } catch (_) {}
    }
  }

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Color _urgencyColor(DateTime day) {
    final diff = day.difference(DateTime.now()).inDays;
    if (diff < 0) return const Color(0xFFE53935);
    if (diff <= 3) return const Color(0xFFF57C00);
    return AppColors.primary;
  }

  bool _hasUtang(DateTime day) => _byDate.containsKey(_dayKey(day));
  List<Map<String, dynamic>> _entriesFor(DateTime day) =>
      _byDate[_dayKey(day)] ?? [];

  List<DateTime?> _buildGrid() {
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final startOffset = firstOfMonth.weekday % 7;
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final cells = <DateTime?>[];
    for (var i = 0; i < startOffset; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(_focusedMonth.year, _focusedMonth.month, d));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  void _showDaySheet(DateTime day) {
    final entries = _entriesFor(day);
    if (entries.isEmpty) return;

    final peso = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );
    final label = DateFormat('MMMM dd, yyyy').format(day);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final maxH = MediaQuery.of(sheetContext).size.height * 0.85;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // handle
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // date header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // entries list (scrollable; prevents overflow on many items)
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (_, i) {
                        final e = entries[i];
                        final name = e['customer_name'] as String? ?? 'Unknown';
                        final amount = e['total_amount'] as double? ?? 0.0;
                        final customerId = e['customer_id'] as int? ?? 0;
                        final urgency = _urgencyColor(day);

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            Navigator.pop(context);
                            if (customerId <= 0) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Customer not found.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            try {
                              final UtangCustomer? customer = await DBService
                                  .instance
                                  .fetchUtangCustomerById(customerId);
                              if (!mounted) return;

                              if (customer != null) {
                                context.push('/utang_summary', extra: customer);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Customer not found.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (_) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to open customer.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                // avatar
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.10),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          AppColors.primary.withOpacity(0.20),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tap to view utang',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // amount + chevron
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: urgency.withOpacity(0.10),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                          color: urgency.withOpacity(0.30),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        peso.format(amount),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: urgency,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final grid = _buildGrid();
    final monthLabel = DateFormat(
      'MMMM yyyy',
    ).format(_focusedMonth).toUpperCase();
    final today = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final density = maxH.isFinite
            ? ((maxH / 360.0).clamp(0.45, 1.0) as num).toDouble()
            : 1.0;
        double s(double v) => v * density;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: s(10)),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(21),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: s(42),
                  height: s(42),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.primary,
                    size: s(22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "UTANG CALENDAR",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: s(13),
                      letterSpacing: 0.8,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                // badge — shows count for focused month only
                Builder(
                  builder: (_) {
                    final countThisMonth = widget.utangList.where((e) {
                      final raw = e['due_date'] as String? ?? '';
                      if (raw.isEmpty) return false;
                      try {
                        final dt = DateTime.parse(raw);
                        return dt.year == _focusedMonth.year &&
                            dt.month == _focusedMonth.month;
                      } catch (_) {
                        return false;
                      }
                    }).length;

                    if (countThisMonth == 0) return const SizedBox();

                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: s(6),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.30),
                            width: 1,
                          ),
                        ),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$countThisMonth',
                                style: TextStyle(
                                  fontSize: s(14),
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                              TextSpan(
                                text: ' utang',
                                style: TextStyle(
                                  fontSize: s(11),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.primary.withOpacity(0.15)),

          // ── Month navigator ──────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: s(6)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _navBtn(Icons.chevron_left, () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month - 1,
                    );
                    _selectedDay = null;
                  });
                }, scale: density),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      monthLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: s(13),
                        letterSpacing: 0.6,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                _navBtn(Icons.chevron_right, () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month + 1,
                    );
                    _selectedDay = null;
                  });
                }, scale: density),
              ],
            ),
          ),

          // ── Calendar grid ────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, s(6)),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalHeight = constraints.maxHeight;
                  final numRows = (grid.length / 7).ceil();
                  final desiredLabelHeight = s(20);
                  final labelHeight = desiredLabelHeight.clamp(
                    0.0,
                    totalHeight,
                  );

                  final desiredRowSpacing = s(2);
                  final maxRowSpacing = numRows <= 1
                      ? 0.0
                      : ((totalHeight - labelHeight) / (numRows - 1))
                          .clamp(0.0, double.infinity);
                  final rowSpacing = desiredRowSpacing.clamp(0.0, maxRowSpacing);

                  return ClipRect(
                    child: Column(
                      children: [
                        // Day-of-week labels
                        SizedBox(
                          height: labelHeight,
                          child: Row(
                            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map(
                              (d) {
                                return Expanded(
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: TextStyle(
                                        fontSize: s(11),
                                        fontWeight: FontWeight.w700,
                                        color:
                                            AppColors.primary.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ).toList(),
                          ),
                        ),
                        // Grid rows (Flex-based to avoid rounding overflows)
                        Expanded(
                          child: Column(
                            children: [
                              for (var row = 0; row < numRows; row++) ...[
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: List.generate(7, (col) {
                                      final i = row * 7 + col;
                                      final day =
                                          i < grid.length ? grid[i] : null;

                                      if (day == null) {
                                        return const Expanded(
                                          child: SizedBox.expand(),
                                        );
                                      }

                                      final isToday =
                                          day.year == today.year &&
                                          day.month == today.month &&
                                          day.day == today.day;
                                      final isSelected =
                                          _selectedDay != null &&
                                          _dayKey(_selectedDay!) ==
                                              _dayKey(day);
                                      final hasUtang = _hasUtang(day);
                                      final borderColor =
                                          hasUtang ? _urgencyColor(day) : null;

                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            if (!hasUtang) return;
                                            setState(() => _selectedDay = day);
                                            _showDaySheet(day);
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : isToday
                                                      ? AppColors.primary
                                                          .withOpacity(0.12)
                                                      : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: hasUtang && !isSelected
                                                  ? Border.all(
                                                      color: borderColor!
                                                          .withOpacity(0.60),
                                                      width: 1.5,
                                                    )
                                                  : null,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${day.day}',
                                                style: TextStyle(
                                                  fontSize: s(12),
                                                  fontWeight: FontWeight.w700,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : isToday
                                                          ? AppColors.primary
                                                          : const Color(
                                                              0xFF1A1A1A,
                                                            ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                if (row != numRows - 1)
                                  SizedBox(height: rowSpacing),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Legend ───────────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, s(8)),
            child: Align(
              alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      children: [
                        _legendDot(
                          const Color(0xFFE53935),
                          'Overdue',
                          scale: density,
                        ),
                        SizedBox(width: 12 * density),
                        _legendDot(
                          const Color(0xFFF57C00),
                          '≤ 3 days',
                          scale: density,
                        ),
                        SizedBox(width: 12 * density),
                        _legendDot(AppColors.primary, 'Upcoming', scale: density),
                      ],
                    ),
                  ),
                ),
              ),

          // ── Empty state ──────────────────────────────────────────────────────
          if (widget.utangList.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: s(16)),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: AppColors.primary,
                        size: s(30),
                      ),
                      SizedBox(height: s(6)),
                      Text(
                        "Walay utang! All clear.",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary.withOpacity(0.6),
                          fontSize: s(13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ],
          ),
        );
      },
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap, {double scale = 1.0}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32 * scale,
          height: 32 * scale,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8 * scale),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20 * scale),
        ),
      );

  Widget _legendDot(Color color, String label, {double scale = 1.0}) => Row(
    children: [
      Container(
        width: 8 * scale,
        height: 8 * scale,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      SizedBox(width: 4 * scale),
      Text(
        label,
        style: TextStyle(
          fontSize: 10 * scale,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    ],
  );
}
