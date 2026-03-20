// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/notification_item.dart';
import '../../models/utang_customer_model.dart';
import '../../providers/db_service_provider.dart';
import '../../providers/notification_provider';
import '../../providers/unread_notif_count_provider.dart';
import '../widgets/notification_3d_card.dart';

// ─── Design Tokens (matches home_screen.dart palette) ─────────────────────────
class _C {
  static const bg        = Color(0xFFF0F4FF);
  static const surface   = Color(0xFFFFFFFF);
  static const border    = Color(0xFFCDD5EE);
  static const brandDeep = Color(0xFF1B3A7A);
  static const brandMid  = Color(0xFF5B6D96);

  // Per-type accent colours
  static const blue   = Color(0xFF2D5BE3);
  static const red    = Color(0xFFD63031);
  static const orange = Color(0xFFE67E00);
  static const amber  = Color(0xFFB7770D);
  static const teal   = Color(0xFF0097A7);
}

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  bool _didMarkSeen = false;

  // Responsive helper — same formula as home_screen.dart
  double _r(BuildContext context, double v) {
    final w = MediaQuery.of(context).size.width;
    return v * (w / 390).clamp(0.85, 1.15);
  }

  String _formatDueText(DateTime? dueDate) {
    if (dueDate == null) return '';
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due   = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final days  = due.difference(today).inDays;
    final status = days == 0
        ? 'Due today'
        : days > 0
            ? 'Due in $days day${days == 1 ? '' : 's'}'
            : 'Overdue by ${days.abs()} day${days.abs() == 1 ? '' : 's'}';
    return '$status • ${DateFormat('MMM d, y').format(dueDate)}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markSeenIfPossible());
  }

  Future<void> _markSeenIfPossible() async {
    if (_didMarkSeen) return;

    final asyncItems = ref.read(notificationsStreamProvider);
    final items = asyncItems.maybeWhen(
      data: (data) => data,
      orElse: () => const <AppNotificationItem>[],
    );

    if (items.isEmpty) return;
    _didMarkSeen = true;

    final db    = await ref.read(databaseProvider.future);
    final batch = db.batch();
    final now   = DateTime.now().toIso8601String();

    for (final n in items) {
      batch.execute(
        '''
        INSERT INTO notif_state (notif_id, seen, seen_at, created_at)
        VALUES (?, 1, ?, ?)
        ON CONFLICT(notif_id) DO UPDATE SET seen=1, seen_at=?
        ''',
        [n.id, now, now, now],
      );
    }

    await batch.commit(noResult: true);
    ref.invalidate(unreadNotifCountProvider);
  }

  // ── Per-type helpers ──────────────────────────────────────────────────────
  IconData _iconFor(AppNotifType type) {
    switch (type) {
      case AppNotifType.ownerPayableSoon:
        return Icons.event_available_rounded;
      case AppNotifType.customerUtangOverdue:
        return Icons.error_outline_rounded;
      case AppNotifType.customerUtangDueToday:
        return Icons.warning_amber_rounded;
      case AppNotifType.customerUtangDueSoon:
        return Icons.schedule_rounded;
      case AppNotifType.lowStock:
        return Icons.inventory_2_rounded;
    }
  }

  String _badgeText(AppNotifType type) {
    switch (type) {
      case AppNotifType.ownerPayableSoon:      return 'PAYABLE';
      case AppNotifType.customerUtangOverdue:  return 'OVERDUE';
      case AppNotifType.customerUtangDueToday: return 'DUE TODAY';
      case AppNotifType.customerUtangDueSoon:  return 'DUE SOON';
      case AppNotifType.lowStock:              return 'LOW STOCK';
    }
  }

  Color _accentColor(AppNotifType type) {
    switch (type) {
      case AppNotifType.ownerPayableSoon:      return _C.blue;
      case AppNotifType.customerUtangOverdue:  return _C.red;
      case AppNotifType.customerUtangDueToday: return _C.orange;
      case AppNotifType.customerUtangDueSoon:  return _C.amber;
      case AppNotifType.lowStock:              return _C.teal;
    }
  }

  bool _isCustomerUtangNotif(AppNotifType type) {
    switch (type) {
      case AppNotifType.customerUtangOverdue:
      case AppNotifType.customerUtangDueToday:
      case AppNotifType.customerUtangDueSoon:
        return true;
      default:
        return false;
    }
  }

  Future<UtangCustomer?> _loadUtangCustomer(int customerId) async {
    final db   = await ref.read(databaseProvider.future);
    final rows = await db.rawQuery(
      '''
      SELECT
        c.id,
        c.first_name,
        c.middle_name,
        c.last_name,
        c.municipality,
        c.barangay,
        c.phone_number,
        COALESCE(sc.total_amount, 0) AS total_amount,
        COALESCE(cp.total_paid, 0)   AS total_paid,
        sc.min_due_date              AS due_date
      FROM customer c
      LEFT JOIN (
        SELECT sc.customer_id,
               SUM(sc.amount)   AS total_amount,
               MIN(sc.due_date) AS min_due_date
        FROM sales_credit sc
        LEFT JOIN credit_status cs ON cs.id = sc.status_id
        WHERE sc.due_date IS NOT NULL
          AND (cs.name = 'unpaid' OR cs.name = 'partial')
        GROUP BY sc.customer_id
      ) sc ON sc.customer_id = c.id
      LEFT JOIN (
        SELECT customer_id, SUM(amount) AS total_paid
        FROM customer_payment
        GROUP BY customer_id
      ) cp ON cp.customer_id = c.id
      WHERE c.id = ?
      LIMIT 1
      ''',
      [customerId],
    );

    if (rows.isEmpty) return null;
    return UtangCustomer.fromMap(rows.first);
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    AppNotificationItem n,
  ) async {
    if (n.type == AppNotifType.ownerPayableSoon) {
      context.push('/owner_utang');
      return;
    }

    if (_isCustomerUtangNotif(n.type)) {
      final customerId = int.tryParse(n.refId ?? '');
      if (customerId == null) {
        context.push('/customer_utang');
        return;
      }

      final customer = await _loadUtangCustomer(customerId);
      if (!context.mounted) return;

      if (customer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Customer not found.'),
            backgroundColor: _C.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      await context.push('/utang_summary', extra: customer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r     = (double v) => _r(context, v);
    final async = ref.watch(notificationsStreamProvider);
    async.whenData((_) => Future.microtask(_markSeenIfPossible));

    return Scaffold(
      backgroundColor: _C.bg,
      // ── App bar — matches home_screen.dart style ──────────────────────────
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(r(64)),
        child: AppBar(
          backgroundColor: _C.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          toolbarHeight: r(64),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: Image.asset(
              'lib/assets/arrowleft.png',
              width: r(22), height: r(22),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.arrow_back_ios_new_rounded,
                size: r(18),
                color: _C.brandDeep,
              ),
            ),
          ),
          title: Text(
            'Notifications',
            style: TextStyle(
              fontSize: r(18),
              fontWeight: FontWeight.w900,
              color: _C.brandDeep,
              letterSpacing: 0.2,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _C.border),
          ),
        ),
      ),

      body: async.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            color: _C.brandDeep,
            strokeWidth: 2.5,
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(r(24)),
            child: Container(
              padding: EdgeInsets.all(r(20)),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(r(20)),
                border: Border.all(color: _C.border, width: 1.5),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.wifi_off_rounded,
                    size: r(40), color: _C.brandMid),
                SizedBox(height: r(12)),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: r(15),
                    fontWeight: FontWeight.w800,
                    color: _C.brandDeep,
                  ),
                ),
                SizedBox(height: r(6)),
                Text(
                  '$e',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: r(13),
                    fontWeight: FontWeight.w600,
                    color: _C.brandMid,
                  ),
                ),
              ]),
            ),
          ),
        ),
        data: (items) {
          final sorted = [...items]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (sorted.isEmpty) return _EmptyState(r: r);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsStreamProvider);
              await ref.read(notificationsStreamProvider.future);
              _didMarkSeen = false;
              await _markSeenIfPossible();
            },
            color: _C.brandDeep,
            backgroundColor: _C.surface,
            child: ListView(
              padding: EdgeInsets.fromLTRB(r(16), r(16), r(16), r(24)),
              children: [
                // ── Count header ─────────────────────────────────────────
                _CountHeader(count: sorted.length, r: r),
                SizedBox(height: r(14)),

                // ── Cards ────────────────────────────────────────────────
                ...List.generate(sorted.length, (i) {
                  final n      = sorted[i];
                  final accent = _accentColor(n.type);
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: i < sorted.length - 1 ? r(10) : 0),
                    child: NotificationCard(
                      icon:        _iconFor(n.type),
                      badgeText:   _badgeText(n.type),
                      accentColor: accent,
                      title:       n.title,
                      message:     n.message,
                      timeText:    DateFormat('MMM d, y  •  h:mm a')
                                       .format(n.createdAt),
                      dueText:     n.dueDate == null
                                       ? null
                                       : _formatDueText(n.dueDate),
                      onTap: () => _handleNotificationTap(context, n),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Count Header ──────────────────────────────────────────────────────────────
class _CountHeader extends StatelessWidget {
  const _CountHeader({required this.count, required this.r});
  final int count;
  final double Function(double) r;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: r(4), height: r(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A3584), Color(0xFF4B8AF0)],
            ),
            borderRadius: BorderRadius.circular(r(4)),
          ),
        ),
        SizedBox(width: r(9)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count notification${count == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: r(13.5),
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B3A7A),
              ),
            ),
            Text(
              'Tap a card to take action',
              style: TextStyle(
                fontSize: r(11),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5B6D96),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.r});
  final double Function(double) r;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: r(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: r(88), height: r(88),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFCDD5EE), width: 2),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: r(44),
                color: const Color(0xFF5B6D96),
              ),
            ),
            SizedBox(height: r(20)),
            Text(
              "You're all caught up!",
              style: TextStyle(
                fontSize: r(18),
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1B3A7A),
              ),
            ),
            SizedBox(height: r(8)),
            Text(
              'No notifications right now.\nCheck back later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: r(14),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5B6D96),
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
