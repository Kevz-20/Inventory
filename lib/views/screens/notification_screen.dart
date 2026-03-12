// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../models/notification_item.dart';
import '../../models/utang_customer_model.dart';
import '../../providers/db_service_provider.dart';
import '../../providers/notification_provider';
import '../../providers/unread_notif_count_provider.dart';
import '../widgets/notification_3d_card.dart';
import 'package:go_router/go_router.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  static const Color _pageBg = Color(0xFFF2F7F5);
  static const Color _cardBg = Color(0xFFEFF8F4);
  static const Color _cardBorder = Color(0xFFBFDCD4);
  static const Color _titleColor = Color(0xFF0B3D35);
  static const Color _subtitleColor = Color(0xFF2F5C54);

  bool _didMarkSeen = false;
  String _formatDueText(DateTime? dueDate) {
    if (dueDate == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final days = due.difference(today).inDays;

    final status = days == 0
        ? 'Due today'
        : days > 0
            ? 'Due in $days day${days == 1 ? '' : 's'}'
            : 'Overdue by ${days.abs()} day${days.abs() == 1 ? '' : 's'}';

    final dateLabel = DateFormat('MMM d, y').format(dueDate);
    return '$status • $dateLabel';
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

    final db = await ref.read(databaseProvider.future);
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (final n in items) {
      batch.execute('''
        INSERT INTO notif_state (notif_id, seen, seen_at, created_at)
        VALUES (?, 1, ?, ?)
        ON CONFLICT(notif_id) DO UPDATE SET seen=1, seen_at=?
      ''', [n.id, now, now, now, now]);
    }

    await batch.commit(noResult: true);

    ref.invalidate(unreadNotifCountProvider);
  }

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
      case AppNotifType.ownerPayableSoon:
        return 'PAYABLE';
      case AppNotifType.customerUtangOverdue:
        return 'OVERDUE';
      case AppNotifType.customerUtangDueToday:
        return 'DUE TODAY';
      case AppNotifType.customerUtangDueSoon:
        return 'DUE SOON';
      case AppNotifType.lowStock:
        return 'LOW STOCK';
    }
  }

  double _badgeOpacity(AppNotifType type) {
    switch (type) {
      case AppNotifType.customerUtangOverdue:
        return 0.22;
      case AppNotifType.customerUtangDueToday:
        return 0.18;
      case AppNotifType.customerUtangDueSoon:
        return 0.14;
      case AppNotifType.ownerPayableSoon:
        return 0.12;
      case AppNotifType.lowStock:
        return 0.12;
    }
  }

  bool _isCustomerUtangNotif(AppNotifType type) {
    switch (type) {
      case AppNotifType.customerUtangOverdue:
      case AppNotifType.customerUtangDueToday:
      case AppNotifType.customerUtangDueSoon:
        return true;
      case AppNotifType.ownerPayableSoon:
      case AppNotifType.lowStock:
        return false;
    }
  }

  Future<UtangCustomer?> _loadUtangCustomer(int customerId) async {
    final db = await ref.read(databaseProvider.future);
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
        COALESCE(cp.total_paid, 0) AS total_paid,
        sc.min_due_date AS due_date
      FROM customer c
      LEFT JOIN (
        SELECT
          sc.customer_id,
          SUM(sc.amount) AS total_amount,
          MIN(sc.due_date) AS min_due_date
        FROM sales_credit sc
        LEFT JOIN credit_status cs ON cs.id = sc.status_id
        WHERE sc.due_date IS NOT NULL
          AND (cs.name = 'unpaid' OR cs.name = 'partial')
        GROUP BY sc.customer_id
      ) sc ON sc.customer_id = c.id
      LEFT JOIN (
        SELECT
          customer_id,
          SUM(amount) AS total_paid
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
      if (!mounted) return;

      if (customer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer not found.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await context.push('/utang_summary', extra: customer);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationsStreamProvider);

    // ✅ once it becomes data, mark seen
    async.whenData((_) => Future.microtask(_markSeenIfPossible));

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: true,
        foregroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.headerTop, AppColors.headerBottom],
            ),
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: $e', textAlign: TextAlign.center),
          ),
        ),
        data: (items) {
          final sortedItems = [...items]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (sortedItems.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 62,
                      width: 62,
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _cardBorder,
                        ),
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.primary,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No notifications right now.',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: _titleColor,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You’re all caught up.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsStreamProvider);
              await ref.read(notificationsStreamProvider.future);
              _didMarkSeen = false; // allow re-mark after refresh
              await _markSeenIfPossible();
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              itemCount: sortedItems.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final n = sortedItems[i];

                // Inside notification_screen.dart -> ListView.separated -> itemBuilder
                return Notification3DCard(
                  icon: _iconFor(n.type),
                  badgeText: _badgeText(n.type),
                  badgeOpacity: _badgeOpacity(n.type),
                  badgeColor: n.type == AppNotifType.customerUtangOverdue
                      ? Colors.red.shade700
                      : null,
                  title: n.title,
                  message: n.message,
                  createdAtText:
                      DateFormat('MMM d, y • h:mm a').format(n.createdAt),
                  dueText: n.dueDate == null
                      ? null
                      : _formatDueText(n.dueDate),
                  onTap: () {
                    _handleNotificationTap(context, n);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// keep your _Notification3DCard unchanged below
