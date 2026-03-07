import 'package:sqflite/sqflite.dart';
import '../models/notification_item.dart';

class NotificationRepository {
  final Database db;
  NotificationRepository(this.db);

  Future<List<AppNotificationItem>> buildNotifications() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
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
      
      // Installment Logic
      final totalMonths = row['plan_months'] as int?;
      final paymentsMade = row['payments_made'] as int? ?? 0;
      String installmentLabel = "";

      if (totalMonths != null && totalMonths > 0) {
        // Current installment is payments made + 1
        int currentInstallment = paymentsMade + 1;
        installmentLabel = " ($currentInstallment/$totalMonths)";
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
          // Keep only key details here; due date is displayed separately in UI.
          message: '${supplier.toLowerCase() == 'owner' ? itemName : '$supplier • $itemName'}$installmentLabel • ₱${amountDue.toStringAsFixed(2)}',
          createdAt: now,
          dueDate: due,
          refId: id,
        ),
      );
    }

    // -------------------------
    // 2) CUSTOMER UTANG due today
    // -------------------------
    final customerDueToday = await db.rawQuery('''
      SELECT
        sc.id AS sales_credit_id,
        sc.amount,
        sc.due_date,
        cs.name AS status_name,
        c.first_name,
        c.middle_name,
        c.last_name
      FROM sales_credit sc
      LEFT JOIN credit_status cs ON cs.id = sc.status_id
      LEFT JOIN customer c ON c.id = sc.customer_id
      WHERE sc.due_date >= ?
        AND sc.due_date < ?
        AND (cs.name = 'unpaid' OR cs.name = 'partial')
      ORDER BY sc.due_date ASC
    ''', [
      todayStart.toIso8601String(),
      todayEnd.toIso8601String(),
    ]);

    for (final row in customerDueToday) {
      final id = row['sales_credit_id'].toString();
      final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;

      final first = (row['first_name'] ?? '').toString().trim();
      final mid = (row['middle_name'] ?? '').toString().trim();
      final last = (row['last_name'] ?? '').toString().trim();
      final fullName = [first, mid, last].where((e) => e.isNotEmpty).join(' ');
      final name = fullName.isEmpty ? 'Customer' : fullName;

      items.add(
        AppNotificationItem(
          id: 'cust_$id',
          type: AppNotifType.customerUtangDueToday,
          title: 'Customer utang',
          message: '$name • ₱${amount.toStringAsFixed(2)}',
          createdAt: now,
          dueDate: todayStart,
          refId: id,
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

    // When stock recovers above threshold, clear old seen-state so the same
    // product can trigger a new unread alert if it becomes low-stock again.
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
          message: '$name • $qty pcs left',
          createdAt: now,
          refId: id,
        ),
      );
    }

    // Keep notif_state aligned with currently active notifications.
    await _removeResolvedNotifState(items.map((e) => e.id).toList());

    // Sort: dueDate first
    items.sort((a, b) {
      final ad = a.dueDate?.millisecondsSinceEpoch ?? 9999999999999;
      final bd = b.dueDate?.millisecondsSinceEpoch ?? 9999999999999;
      return ad.compareTo(bd);
    });

    return items;
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
