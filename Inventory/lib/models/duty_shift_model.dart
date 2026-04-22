class DutyShift {
  final int id;
  final int accountId;
  final int memberId;
  final String memberName;
  final String startedAt;
  final String? endedAt;

  const DutyShift({
    required this.id,
    required this.accountId,
    required this.memberId,
    required this.memberName,
    required this.startedAt,
    this.endedAt,
  });

  bool get isActive => endedAt == null;

  Duration get elapsed {
    final start = DateTime.tryParse(startedAt) ?? DateTime.now();
    final end = endedAt != null
        ? (DateTime.tryParse(endedAt!) ?? DateTime.now())
        : DateTime.now();
    return end.difference(start);
  }

  String get elapsedLabel {
    final d = elapsed;
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '<1m';
  }

  factory DutyShift.fromMap(Map<String, dynamic> m) => DutyShift(
        id: m['id'] as int,
        accountId: m['account_id'] as int,
        memberId: m['member_id'] as int,
        memberName: (m['member_name'] ?? 'Unknown').toString(),
        startedAt: (m['started_at'] ?? '').toString(),
        endedAt: m['ended_at'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'account_id': accountId,
        'member_id': memberId,
        'member_name': memberName,
        'started_at': startedAt,
        'ended_at': endedAt,
      };
}
