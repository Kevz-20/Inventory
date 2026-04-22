// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../repositories/member_activity_repository.dart';
import '../../view_models/member_activity_view_model.dart';

// ─── Design tokens (matches home_screen palette) ───────────────────────────────
class _C {
  static const bg        = Color(0xFFF0F4FF);
  static const surface   = Color(0xFFFFFFFF);
  static const border    = Color(0xFFCDD5EE);
  static const brandDeep = Color(0xFF1B3A7A);
  static const brandMid  = Color(0xFF5B6D96);
  static const heroStart = Color(0xFF1A3584);
  static const heroMid   = Color(0xFF2456D0);
  static const heroEnd   = Color(0xFF4B8AF0);
  static const green     = Color(0xFF00897B);
  static const greenBg   = Color(0xFFE0F2F1);
  static const blue      = Color(0xFF2D5BE3);
  static const blueBg    = Color(0xFFEEF2FF);
  static const red       = Color(0xFFD63031);
  static const redBg     = Color(0xFFFFF0F0);
  static const orange    = Color(0xFFE67E00);
  static const orangeBg  = Color(0xFFFFF3E0);
}

class MemberActivityScreen extends ConsumerStatefulWidget {
  const MemberActivityScreen({super.key});

  @override
  ConsumerState<MemberActivityScreen> createState() =>
      _MemberActivityScreenState();
}

class _MemberActivityScreenState
    extends ConsumerState<MemberActivityScreen> {
  final _currency =
      NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

  double _r(double v) {
    final w = MediaQuery.of(context).size.width;
    return v * (w / 390).clamp(0.85, 1.15);
  }

  Future<void> _pickCustomRange(MemberActivityNotifier notifier,
      MemberActivityState state) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 3),
      lastDate: DateTime.now(),
      initialDateRange:
          DateTimeRange(start: state.fromDate, end: state.toDate),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _C.heroMid,
            onPrimary: Colors.white,
            surface: _C.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      await notifier.setCustomRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memberActivityProvider);
    final notifier = ref.read(memberActivityProvider.notifier);

    final totalSales =
        state.members.fold<double>(0, (s, m) => s + m.totalSales);
    final totalExpenses =
        state.members.fold<double>(0, (s, m) => s + m.totalExpenses);
    final activeCount =
        state.members.where((m) => m.totalTransactions > 0).length;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Date filter strip ──────────────────────────────────────────────
          _buildFilterStrip(state, notifier),

          // ── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _C.heroMid))
                : state.error != null
                    ? _buildError(state.error!)
                    : RefreshIndicator(
                        onRefresh: notifier.load,
                        color: _C.heroMid,
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(
                              _r(16), _r(14), _r(16), _r(32)),
                          children: [
                            _buildSummaryCard(
                                totalSales, totalExpenses, activeCount),
                            SizedBox(height: _r(18)),
                            if (state.members.isEmpty)
                              _buildEmptyState()
                            else
                              ...state.members.map(
                                (m) => Padding(
                                  padding:
                                      EdgeInsets.only(bottom: _r(10)),
                                  child: _MemberCard(
                                    summary: m,
                                    currency: _currency,
                                    r: _r,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _C.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            size: _r(20), color: _C.brandDeep),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Member Activity',
        style: TextStyle(
          fontSize: _r(19),
          fontWeight: FontWeight.w900,
          color: _C.brandDeep,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.border),
      ),
    );
  }

  // ── Filter strip ──────────────────────────────────────────────────────────
  Widget _buildFilterStrip(
      MemberActivityState state, MemberActivityNotifier notifier) {
    const filters = [
      (MemberDateFilter.today, 'Today'),
      (MemberDateFilter.week, 'This Week'),
      (MemberDateFilter.month, 'This Month'),
      (MemberDateFilter.custom, 'Custom'),
    ];

    final dateFmt = DateFormat('MMM d');
    String customLabel = 'Custom';
    if (state.filter == MemberDateFilter.custom) {
      if (state.fromDate == state.toDate ||
          state.fromDate.isAtSameMomentAs(state.toDate)) {
        customLabel = dateFmt.format(state.fromDate);
      } else {
        customLabel =
            '${dateFmt.format(state.fromDate)} – ${dateFmt.format(state.toDate)}';
      }
    }

    return Container(
      color: _C.surface,
      padding:
          EdgeInsets.fromLTRB(_r(12), _r(10), _r(12), _r(10)),
      child: Row(
        children: filters.map((entry) {
          final (filter, baseLabel) = entry;
          final label =
              filter == MemberDateFilter.custom ? customLabel : baseLabel;
          final selected = state.filter == filter;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _r(3)),
              child: GestureDetector(
                onTap: () => filter == MemberDateFilter.custom
                    ? _pickCustomRange(notifier, state)
                    : notifier.setFilter(filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: EdgeInsets.symmetric(vertical: _r(8)),
                  decoration: BoxDecoration(
                    color: selected ? _C.heroMid : _C.blueBg,
                    borderRadius: BorderRadius.circular(_r(10)),
                    border: Border.all(
                      color: selected ? _C.heroMid : _C.border,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: _r(11),
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : _C.brandMid,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Summary card ──────────────────────────────────────────────────────────
  Widget _buildSummaryCard(
      double totalSales, double totalExpenses, int activeCount) {
    return Container(
      padding: EdgeInsets.all(_r(16)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.heroStart, _C.heroMid, _C.heroEnd],
        ),
        borderRadius: BorderRadius.circular(_r(22)),
        boxShadow: [
          BoxShadow(
            color: _C.heroStart.withOpacity(0.30),
            blurRadius: _r(24),
            offset: Offset(0, _r(8)),
          ),
        ],
      ),
      child: Row(
        children: [
          _SummaryCell(
            icon: Icons.trending_up_rounded,
            label: 'Total Sales',
            value: _currency.format(totalSales),
            r: _r,
          ),
          _Divider(r: _r),
          _SummaryCell(
            icon: Icons.receipt_outlined,
            label: 'Total Expenses',
            value: _currency.format(totalExpenses),
            r: _r,
          ),
          _Divider(r: _r),
          _SummaryCell(
            icon: Icons.people_outline_rounded,
            label: 'Active',
            value:
                '$activeCount member${activeCount == 1 ? '' : 's'}',
            r: _r,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) => Center(
        child: Padding(
          padding: EdgeInsets.all(_r(24)),
          child: Text(error,
              textAlign: TextAlign.center,
              style: TextStyle(color: _C.red, fontSize: _r(14))),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: _r(56)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline_rounded,
                  size: _r(56), color: _C.border),
              SizedBox(height: _r(14)),
              Text(
                'No activity in this period',
                style: TextStyle(
                    fontSize: _r(15),
                    fontWeight: FontWeight.w700,
                    color: _C.brandMid),
              ),
              SizedBox(height: _r(6)),
              Text(
                'Try selecting a different date range',
                style: TextStyle(
                    fontSize: _r(13), color: _C.brandMid),
              ),
            ],
          ),
        ),
      );
}

// ─── Summary cell ──────────────────────────────────────────────────────────────
class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.r,
  });

  final IconData icon;
  final String label, value;
  final double Function(double) r;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: r(17), color: Colors.white.withOpacity(0.85)),
          SizedBox(height: r(5)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: r(12.5),
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: r(2)),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: r(10),
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.r});
  final double Function(double) r;

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: r(44),
        color: Colors.white.withOpacity(0.28),
      );
}

// ─── Member card ──────────────────────────────────────────────────────────────
class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.summary,
    required this.currency,
    required this.r,
  });

  final MemberActivitySummary summary;
  final NumberFormat currency;
  final double Function(double) r;

  static const _avatarColors = [
    Color(0xFF2456D0),
    Color(0xFF00897B),
    Color(0xFFE67E00),
    Color(0xFF0097A7),
    Color(0xFF6C3FC4),
    Color(0xFFD63031),
  ];

  Color get _avatarColor =>
      _avatarColors[summary.memberName.hashCode.abs() % _avatarColors.length];

  String get _initials {
    final parts = summary.memberName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return summary.memberName.isNotEmpty
        ? summary.memberName[0].toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    final hasActivity = summary.totalTransactions > 0;
    final net = summary.net;
    final netPositive = net >= 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(r(20)),
        border: Border.all(color: const Color(0xFFCDD5EE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B3A7A).withOpacity(0.06),
            blurRadius: r(12),
            offset: Offset(0, r(3)),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(r(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: r(44),
                  height: r(44),
                  decoration: BoxDecoration(
                    color: _avatarColor,
                    borderRadius: BorderRadius.circular(r(14)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials,
                    style: TextStyle(
                      fontSize: r(16),
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: r(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.memberName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: r(15.5),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B3A7A),
                        ),
                      ),
                      SizedBox(height: r(2)),
                      Text(
                        hasActivity
                            ? 'Active this period'
                            : 'No activity',
                        style: TextStyle(
                          fontSize: r(12),
                          fontWeight: FontWeight.w600,
                          color: hasActivity
                              ? const Color(0xFF00897B)
                              : const Color(0xFF5B6D96),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasActivity)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: r(10), vertical: r(4)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(r(20)),
                      border: Border.all(
                          color: const Color(0xFF00897B).withOpacity(0.3)),
                    ),
                    child: Text(
                      '${summary.totalTransactions} txn${summary.totalTransactions == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: r(11),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00897B),
                      ),
                    ),
                  ),
              ],
            ),

            if (hasActivity) ...[
              SizedBox(height: r(12)),
              Container(height: 1, color: const Color(0xFFCDD5EE)),
              SizedBox(height: r(12)),

              // ── Stats row ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.point_of_sale_rounded,
                      iconColor: const Color(0xFF2D5BE3),
                      iconBg: const Color(0xFFEEF2FF),
                      label: 'Sales',
                      primary: currency.format(summary.totalSales),
                      secondary:
                          '${summary.saleCount} txn${summary.saleCount == 1 ? '' : 's'}',
                      r: r,
                    ),
                  ),
                  SizedBox(width: r(8)),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.payments_outlined,
                      iconColor: const Color(0xFFD63031),
                      iconBg: const Color(0xFFFFF0F0),
                      label: 'Expenses',
                      primary: currency.format(summary.totalExpenses),
                      secondary:
                          '${summary.expenseCount} item${summary.expenseCount == 1 ? '' : 's'}',
                      r: r,
                    ),
                  ),
                  SizedBox(width: r(8)),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.inventory_2_outlined,
                      iconColor: const Color(0xFFE67E00),
                      iconBg: const Color(0xFFFFF3E0),
                      label: 'Stock-ins',
                      primary: '${summary.stockInCount}',
                      secondary:
                          'entr${summary.stockInCount == 1 ? 'y' : 'ies'}',
                      r: r,
                    ),
                  ),
                ],
              ),

              SizedBox(height: r(10)),

              // ── Net contribution bar ──────────────────────────────────
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: r(12), vertical: r(9)),
                decoration: BoxDecoration(
                  color: netPositive
                      ? const Color(0xFFE0F2F1)
                      : const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(r(12)),
                  border: Border.all(
                    color: (netPositive
                            ? const Color(0xFF00897B)
                            : const Color(0xFFD63031))
                        .withOpacity(0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      netPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: r(16),
                      color: netPositive
                          ? const Color(0xFF00897B)
                          : const Color(0xFFD63031),
                    ),
                    SizedBox(width: r(6)),
                    Text(
                      'Net contribution',
                      style: TextStyle(
                        fontSize: r(12),
                        fontWeight: FontWeight.w600,
                        color: netPositive
                            ? const Color(0xFF00897B)
                            : const Color(0xFFD63031),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${netPositive ? '+' : ''}${currency.format(net)}',
                      style: TextStyle(
                        fontSize: r(13),
                        fontWeight: FontWeight.w900,
                        color: netPositive
                            ? const Color(0xFF00897B)
                            : const Color(0xFFD63031),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Stat tile ────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.primary,
    required this.secondary,
    required this.r,
  });

  final IconData icon;
  final Color iconColor, iconBg;
  final String label, primary, secondary;
  final double Function(double) r;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(r(10)),
      decoration: BoxDecoration(
        color: iconBg,
        borderRadius: BorderRadius.circular(r(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: r(16), color: iconColor),
          SizedBox(height: r(6)),
          Text(
            primary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: r(13),
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1B3A7A),
            ),
          ),
          SizedBox(height: r(2)),
          Text(
            secondary,
            maxLines: 1,
            style: TextStyle(
              fontSize: r(10.5),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5B6D96),
            ),
          ),
        ],
      ),
    );
  }
}
