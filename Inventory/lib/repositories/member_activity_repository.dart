import 'package:sqflite/sqflite.dart';

class MemberActivitySummary {
  final int? memberId;
  final String memberName;
  final int saleCount;
  final double totalSales;
  final int expenseCount;
  final double totalExpenses;
  final int stockInCount;

  const MemberActivitySummary({
    this.memberId,
    required this.memberName,
    this.saleCount = 0,
    this.totalSales = 0.0,
    this.expenseCount = 0,
    this.totalExpenses = 0.0,
    this.stockInCount = 0,
  });

  double get net => totalSales - totalExpenses;

  int get totalTransactions => saleCount + expenseCount + stockInCount;

  MemberActivitySummary copyWith({
    int? saleCount,
    double? totalSales,
    int? expenseCount,
    double? totalExpenses,
    int? stockInCount,
  }) =>
      MemberActivitySummary(
        memberId: memberId,
        memberName: memberName,
        saleCount: saleCount ?? this.saleCount,
        totalSales: totalSales ?? this.totalSales,
        expenseCount: expenseCount ?? this.expenseCount,
        totalExpenses: totalExpenses ?? this.totalExpenses,
        stockInCount: stockInCount ?? this.stockInCount,
      );
}

class MemberActivityRepository {
  final Database db;
  MemberActivityRepository(this.db);

  static String _memberName(Map<String, dynamic> row) {
    final parts = [
      (row['first_name'] ?? '').toString().trim(),
      (row['middle_name'] ?? '').toString().trim(),
      (row['last_name'] ?? '').toString().trim(),
    ].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? 'Unknown' : parts.join(' ');
  }

  static String _fallbackName(Map<String, dynamic> row) {
    final first = (row['created_by_first_name'] ?? '').toString().trim();
    final last = (row['created_by_last_name'] ?? '').toString().trim();
    final combined = [first, last].where((s) => s.isNotEmpty).join(' ');
    return combined.isEmpty ? 'Unknown' : combined;
  }

  static String _keyFor(int? id, String name) =>
      id != null ? 'id:$id' : 'name:${name.toLowerCase()}';

  Future<List<MemberActivitySummary>> getActivity({
    required String fromDate,
    required String toDate,
  }) async {
    final Map<String, MemberActivitySummary> map = {};

    // Seed all registered members so they appear even with no activity
    final memberRows = await db.rawQuery('''
      SELECT id, first_name, middle_name, last_name
      FROM slpa_member WHERE is_deleted = 0 ORDER BY first_name ASC
    ''');
    for (final row in memberRows) {
      final id = row['id'] as int;
      final name = _memberName(row);
      map[_keyFor(id, name)] =
          MemberActivitySummary(memberId: id, memberName: name);
    }

    // Sales
    final salesRows = await db.rawQuery('''
      SELECT
        s.created_by_member_id,
        m.first_name, m.middle_name, m.last_name,
        s.created_by_first_name, s.created_by_last_name,
        COUNT(s.id)           AS sale_count,
        COALESCE(SUM(s.total), 0) AS total_sales
      FROM sales s
      LEFT JOIN slpa_member m ON m.id = s.created_by_member_id
      WHERE s.is_deleted = 0 AND DATE(s.created_at) BETWEEN ? AND ?
      GROUP BY COALESCE(s.created_by_member_id,
               s.created_by_first_name || '|' || s.created_by_last_name)
    ''', [fromDate, toDate]);

    for (final row in salesRows) {
      final id = row['created_by_member_id'] as int?;
      final name = id != null ? _memberName(row) : _fallbackName(row);
      final k = _keyFor(id, name);
      final base = map[k] ??
          MemberActivitySummary(memberId: id, memberName: name);
      map[k] = base.copyWith(
        saleCount: (row['sale_count'] as num?)?.toInt() ?? 0,
        totalSales: (row['total_sales'] as num?)?.toDouble() ?? 0.0,
      );
    }

    // Expenses
    final expenseRows = await db.rawQuery('''
      SELECT
        e.created_by_member_id,
        m.first_name, m.middle_name, m.last_name,
        e.created_by_first_name, e.created_by_last_name,
        COUNT(e.id)              AS expense_count,
        COALESCE(SUM(e.amount), 0) AS total_expenses
      FROM expenses e
      LEFT JOIN slpa_member m ON m.id = e.created_by_member_id
      WHERE e.is_deleted = 0 AND DATE(e.created_at) BETWEEN ? AND ?
      GROUP BY COALESCE(e.created_by_member_id,
               e.created_by_first_name || '|' || e.created_by_last_name)
    ''', [fromDate, toDate]);

    for (final row in expenseRows) {
      final id = row['created_by_member_id'] as int?;
      final name = id != null ? _memberName(row) : _fallbackName(row);
      final k = _keyFor(id, name);
      final base = map[k] ??
          MemberActivitySummary(memberId: id, memberName: name);
      map[k] = base.copyWith(
        expenseCount: (row['expense_count'] as num?)?.toInt() ?? 0,
        totalExpenses: (row['total_expenses'] as num?)?.toDouble() ?? 0.0,
      );
    }

    // Stock-ins
    final stockRows = await db.rawQuery('''
      SELECT
        si.created_by_member_id,
        m.first_name, m.middle_name, m.last_name,
        COUNT(si.id) AS stock_count
      FROM stock_in si
      LEFT JOIN slpa_member m ON m.id = si.created_by_member_id
      WHERE si.is_deleted = 0 AND DATE(si.created_at) BETWEEN ? AND ?
      GROUP BY si.created_by_member_id
    ''', [fromDate, toDate]);

    for (final row in stockRows) {
      final id = row['created_by_member_id'] as int?;
      final name = id != null ? _memberName(row) : 'Unknown';
      final k = _keyFor(id, name);
      final base = map[k] ??
          MemberActivitySummary(memberId: id, memberName: name);
      map[k] = base.copyWith(
        stockInCount: (row['stock_count'] as num?)?.toInt() ?? 0,
      );
    }

    final result = map.values.toList()
      ..sort((a, b) {
        // Active members first, sorted by total sales
        final aActive = a.totalTransactions > 0 ? 0 : 1;
        final bActive = b.totalTransactions > 0 ? 0 : 1;
        if (aActive != bActive) return aActive.compareTo(bActive);
        final sc = b.totalSales.compareTo(a.totalSales);
        if (sc != 0) return sc;
        return a.memberName.compareTo(b.memberName);
      });

    return result;
  }
}
