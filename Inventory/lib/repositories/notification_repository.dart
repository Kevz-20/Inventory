import 'package:sqflite/sqflite.dart';
import '../models/notification_item.dart';

class NotificationRepository {
  final Database db;
  NotificationRepository(this.db);

  Future<List<AppNotificationItem>> buildNotifications() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final threeDaysFromNow = todayStart.add(const Duration(days: 3));

    final items = <AppNotificationItem>[];

    // -------------------------
    // 1) OWNER PAYABLE due within 3 days
    // Table: payable
    // -------------------------
    final ownerPayables = await db.rawQuery('''
      SELECT
        p.id,
        p.supplier_name,
        p.item,
        p.remaining_amount,
        p.plan_monthly,
        p.plan_months, -- Total months in plan
        COALESCE(p.plan_monthly, p.remaining_amount) AS current_due_amount,
        COALESCE(p.next_due_date, p.due_date) AS due,
        -- Count existing payments for this payable to determine current installment number
        (SELECT COUNT(*) FROM payable_payment WHERE payable_id = p.id) AS payments_made
      FROM payable p
      WHERE p.is_paid = 0
        AND due IS NOT NULL
        AND due >= ?
        AND due <= ?
      ORDER BY due ASC
    ''', [
      todayStart.toIso8601String(),
      threeDaysFromNow.toIso8601String(),
    ]);

    for (final row in ownerPayables) {
      final id = row['id'].toString();
      final supplier = (row['supplier_name'] ?? 'Supplier').toString();
      final itemName = (row['item'] ?? 'Item').toString();
      final amountDue = (row['current_due_amount'] as num?)?.toDouble() ?? 0.0;

      final totalMonths = row['plan_months'] as int?;
      final paymentsMade = row['payments_made'] as int? ?? 0;
      var installmentLabel = '';

      if (totalMonths != null && totalMonths > 0) {
        final currentInstallment = paymentsMade + 1;
        installmentLabel = ' ($currentInstallment/$totalMonths)';
      }

      final dueStr = row['due']?.toString();
      if (dueStr == null) continue;
      final due = DateTime.tryParse(dueStr);
      if (due == null) continue;

      items.add(
        AppNotificationItem(
          id: 'owner_$id',
          type: AppNotifType.ownerPayableSoon,
          title: 'Owner payable',
          message:
              '${supplier.toLowerCase() == 'owner' ? itemName : '$supplier \u2022 $itemName'}$installmentLabel \u2022 \u20B1${amountDue.toStringAsFixed(2)}',
          createdAt: now,
          dueDate: due,
          refId: id,
        ),
      );
    }

    // -------------------------
    // 2) CUSTOMER UTANG (overdue / today / due soon)
    // -------------------------
    final customerUtang = await db.rawQuery('''
      SELECT
        c.id AS customer_id,
        c.first_name,
        c.middle_name,
        c.last_name,
        MAX(0, COALESCE(sc.total_amount, 0) - COALESCE(cp.total_paid, 0)) AS total_balance,
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
      WHERE sc.min_due_date IS NOT NULL
        AND sc.min_due_date <= ?
        AND (COALESCE(sc.total_amount, 0) - COALESCE(cp.total_paid, 0)) > 0
      ORDER BY sc.min_due_date ASC
      LIMIT 100
    ''', [
      threeDaysFromNow.toIso8601String(),
    ]);

    for (final row in customerUtang) {
      final customerIdRaw = row['customer_id'];
      if (customerIdRaw == null) continue;
      final customerId = (customerIdRaw as num).toInt();

      final dueStr = row['due_date']?.toString();
      if (dueStr == null) continue;
      final due = DateTime.tryParse(dueStr);
      if (due == null) continue;

      final balance = (row['total_balance'] as num?)?.toDouble() ?? 0.0;

      final first = (row['first_name'] ?? '').toString().trim();
      final mid = (row['middle_name'] ?? '').toString().trim();
      final last = (row['last_name'] ?? '').toString().trim();
      final fullName = [first, mid, last].where((e) => e.isNotEmpty).join(' ');
      final name = fullName.isEmpty ? 'Customer' : fullName;

      final dueOnly = DateTime(due.year, due.month, due.day);
      final days = dueOnly.difference(todayStart).inDays;

      final AppNotifType type = days < 0
          ? AppNotifType.customerUtangOverdue
          : days == 0
              ? AppNotifType.customerUtangDueToday
              : AppNotifType.customerUtangDueSoon;

      items.add(
        AppNotificationItem(
          id: 'cust_$customerId',
          type: type,
          title: 'Customer utang',
          message: '$name \u2022 \u20B1${balance.toStringAsFixed(2)}',
          createdAt: now,
          dueDate: due,
          refId: customerId.toString(),
        ),
      );
    }

    // -------------------------
    // 3) LOW STOCK (<= 10)
    // -------------------------
    final allProducts = await db.query(
      'product',
      columns: ['id', 'name', 'quantity'],
      orderBy: 'quantity ASC',
    );

    final recoveredNotifIds = <String>[];
    for (final row in allProducts) {
      final productId = row['id'];
      final qty = (row['quantity'] as num?)?.toInt() ?? 0;
      if (productId != null && qty > 10) {
        recoveredNotifIds.add('stock_$productId');
      }
    }

    if (recoveredNotifIds.isNotEmpty) {
      final placeholders = List.filled(recoveredNotifIds.length, '?').join(',');
      await db.rawDelete(
        'DELETE FROM notif_state WHERE notif_id IN ($placeholders)',
        recoveredNotifIds,
      );
    }

    final lowStock = allProducts.where((row) {
      final qty = (row['quantity'] as num?)?.toInt() ?? 0;
      return qty <= 10;
    });

    for (final row in lowStock) {
      final id = row['id'].toString();
      final name = (row['name'] ?? 'Item').toString();
      final qty = (row['quantity'] as num?)?.toInt() ?? 0;

      items.add(
        AppNotificationItem(
          id: 'stock_$id',
          type: AppNotifType.lowStock,
          title: 'Low stock',
          message: '$name \u2022 $qty pcs left',
          createdAt: now,
          refId: id,
        ),
      );
    }

    await _removeResolvedNotifState(items.map((e) => e.id).toList());
    await _applyStableCreatedAt(items, now);

    items.sort((a, b) {
      final ad = a.dueDate?.millisecondsSinceEpoch ?? 9999999999999;
      final bd = b.dueDate?.millisecondsSinceEpoch ?? 9999999999999;
      return ad.compareTo(bd);
    });

    return items;
  }

  Future<void> _applyStableCreatedAt(
    List<AppNotificationItem> items,
    DateTime now,
  ) async {
    if (items.isEmpty) return;

    final ids = items.map((e) => e.id).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT notif_id, created_at FROM notif_state WHERE notif_id IN ($placeholders)',
      ids,
    );

    final createdAtMap = <String, DateTime>{};
    for (final r in rows) {
      final id = r['notif_id']?.toString();
      final raw = r['created_at']?.toString();
      if (id == null || raw == null || raw.isEmpty) continue;
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) createdAtMap[id] = parsed;
    }

    final batch = db.batch();
    final nowIso = now.toIso8601String();

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final stored = createdAtMap[item.id];
      final effectiveCreatedAt = stored ?? now;

      items[i] = AppNotificationItem(
        id: item.id,
        type: item.type,
        title: item.title,
        message: item.message,
        createdAt: effectiveCreatedAt,
        dueDate: item.dueDate,
        refId: item.refId,
      );

      if (stored == null) {
        batch.execute(
          'INSERT OR IGNORE INTO notif_state (notif_id, seen, created_at) VALUES (?, 0, ?)',
          [item.id, nowIso],
        );
      }
    }

    await batch.commit(noResult: true);
  }

  Future<void> _removeResolvedNotifState(List<String> activeIds) async {
    const condition =
        "(notif_id LIKE 'owner_%' OR notif_id LIKE 'cust_%' OR notif_id LIKE 'stock_%')";

    if (activeIds.isEmpty) {
      await db.rawDelete('DELETE FROM notif_state WHERE $condition');
      return;
    }

    final placeholders = List.filled(activeIds.length, '?').join(',');
    await db.rawDelete(
      'DELETE FROM notif_state WHERE $condition AND notif_id NOT IN ($placeholders)',
      activeIds,
    );
  }
}
