// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/duty_shift_model.dart';
import '../../view_models/duty_shift_view_model.dart';

class _C {
  static const bg       = Color(0xFFF0F4FF);
  static const surface  = Color(0xFFFFFFFF);
  static const border   = Color(0xFFCDD5EE);
  static const titleClr = Color(0xFF1B3A7A);
  static const subClr   = Color(0xFF5B6D96);
  static const blue     = Color(0xFF2D5BE3);
  static const heroStart = Color(0xFF1A3584);
  static const heroMid   = Color(0xFF2456D0);
  static const heroEnd   = Color(0xFF4B8AF0);
}

class DutyShiftScreen extends ConsumerStatefulWidget {
  const DutyShiftScreen({super.key});

  @override
  ConsumerState<DutyShiftScreen> createState() => _DutyShiftScreenState();
}

class _DutyShiftScreenState extends ConsumerState<DutyShiftScreen> {
  double get _w => MediaQuery.of(context).size.width;
  double _r(double v) => v * (_w / 390).clamp(0.85, 1.15);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dutyShiftProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(state),
    );
  }

  PreferredSizeWidget _buildAppBar() => PreferredSize(
        preferredSize: Size.fromHeight(_r(60)),
        child: AppBar(
          backgroundColor: _C.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Image.asset(
              'lib/assets/arrowleft.png',
              width: _r(22),
              height: _r(22),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _C.titleClr,
                size: _r(20),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Duty Shifts',
            style: TextStyle(
              color: _C.titleClr,
              fontWeight: FontWeight.w900,
              fontSize: _r(20),
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _C.border),
          ),
        ),
      );

  Widget _buildBody(DutyShiftState state) {
    final pad = _r(16);
    final completedShifts = state.history.where((s) => !s.isActive).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(pad, _r(16), pad, _r(24)),
      children: [
        // Currently on duty — read-only info card
        if (state.activeShift != null) ...[
          _ActiveInfoCard(shift: state.activeShift!, r: _r),
          SizedBox(height: _r(20)),
        ],

        // Shift history
        if (completedShifts.isNotEmpty) ...[
          Text(
            'Shift History',
            style: TextStyle(
              fontSize: _r(15),
              fontWeight: FontWeight.w900,
              color: _C.titleClr,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: _r(10)),
          ...completedShifts.map((s) => _ShiftHistoryCard(shift: s, r: _r)),
        ],

        if (state.activeShift == null && completedShifts.isEmpty)
          _EmptyState(r: _r),
      ],
    );
  }
}

// ─── Currently on duty — read-only ────────────────────────────────────────────
class _ActiveInfoCard extends StatelessWidget {
  const _ActiveInfoCard({required this.shift, required this.r});
  final DutyShift shift;
  final double Function(double) r;

  @override
  Widget build(BuildContext context) {
    final initials    = _initials(shift.memberName);
    final avatarColor = _nameColor(shift.memberName);
    final startTime   = _fmtTime(shift.startedAt);
    final startDate   = _fmtDate(shift.startedAt);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.heroStart, _C.heroMid, _C.heroEnd],
        ),
        borderRadius: BorderRadius.circular(r(24)),
        boxShadow: [
          BoxShadow(
            color: _C.heroStart.withOpacity(0.32),
            blurRadius: r(24),
            offset: Offset(0, r(8)),
          ),
        ],
      ),
      padding: EdgeInsets.all(r(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: r(10),
                height: r(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withOpacity(0.5),
                      blurRadius: r(6),
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              SizedBox(width: r(7)),
              Text(
                'CURRENTLY ON DUTY',
                style: TextStyle(
                  fontSize: r(11),
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.80),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: r(16)),
          Row(
            children: [
              Container(
                width: r(54),
                height: r(54),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: avatarColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.30),
                    width: 2,
                  ),
                ),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: r(20),
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: r(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift.memberName,
                      style: TextStyle(
                        fontSize: r(20),
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: r(4)),
                    Text(
                      'Since $startTime · $startDate',
                      style: TextStyle(
                        fontSize: r(12.5),
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.72),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: r(10),
                  vertical: r(5),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(r(10)),
                  border: Border.all(color: Colors.white.withOpacity(0.28)),
                ),
                child: Text(
                  shift.elapsedLabel,
                  style: TextStyle(
                    fontSize: r(13),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Completed shift row ───────────────────────────────────────────────────────
class _ShiftHistoryCard extends StatelessWidget {
  const _ShiftHistoryCard({required this.shift, required this.r});
  final DutyShift shift;
  final double Function(double) r;

  @override
  Widget build(BuildContext context) {
    final initials    = _initials(shift.memberName);
    final avatarColor = _nameColor(shift.memberName);
    final startTime   = _fmtTime(shift.startedAt);
    final endTime     = shift.endedAt != null ? _fmtTime(shift.endedAt!) : '–';
    final dateLabel   = _fmtDate(shift.startedAt);

    return Container(
      margin: EdgeInsets.only(bottom: r(10)),
      padding: EdgeInsets.all(r(14)),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(r(18)),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF93A4CF).withOpacity(0.07),
            blurRadius: r(10),
            offset: Offset(0, r(4)),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: r(42),
            height: r(42),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: avatarColor.withOpacity(0.80),
              shape: BoxShape.circle,
            ),
            child: Text(
              initials,
              style: TextStyle(
                fontSize: r(15),
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
                  shift.memberName,
                  style: TextStyle(
                    fontSize: r(14),
                    fontWeight: FontWeight.w800,
                    color: _C.titleClr,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: r(3)),
                Text(
                  '$dateLabel  ·  $startTime → $endTime',
                  style: TextStyle(
                    fontSize: r(12),
                    fontWeight: FontWeight.w600,
                    color: _C.subClr,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: r(8)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: r(9), vertical: r(4)),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(r(8)),
              border: Border.all(color: _C.border),
            ),
            child: Text(
              shift.elapsedLabel,
              style: TextStyle(
                fontSize: r(12),
                fontWeight: FontWeight.w800,
                color: _C.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.r});
  final double Function(double) r;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: r(48)),
      child: Column(
        children: [
          Icon(Icons.history_toggle_off_rounded,
              size: r(48), color: _C.subClr.withOpacity(0.4)),
          SizedBox(height: r(12)),
          Text(
            'No shift history yet.',
            style: TextStyle(
              fontSize: r(14),
              fontWeight: FontWeight.w700,
              color: _C.subClr,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────────────
String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

Color _nameColor(String name) {
  const palette = [
    Color(0xFF1A3584), Color(0xFF00897B), Color(0xFFAD1457),
    Color(0xFF6A1B9A), Color(0xFF00838F), Color(0xFF4527A0),
    Color(0xFF2E7D32), Color(0xFF558B2F),
  ];
  final idx = name.codeUnits.fold(0, (a, b) => a + b) % palette.length;
  return palette[idx];
}

String _fmtTime(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  return DateFormat('h:mm a').format(dt.toLocal());
}

String _fmtDate(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  final now = DateTime.now();
  if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
    return 'Today';
  }
  final yesterday = now.subtract(const Duration(days: 1));
  if (dt.year == yesterday.year &&
      dt.month == yesterday.month &&
      dt.day == yesterday.day) {
    return 'Yesterday';
  }
  return DateFormat('MMM d, yyyy').format(dt.toLocal());
}
