import 'package:flutter/material.dart';

class SyncStatusBadge extends StatelessWidget {
  final String? syncStatus;
  final String? lastSyncedAt;
  final bool compact;
  final VoidCallback? onTap;

  const SyncStatusBadge({
    super.key,
    required this.syncStatus,
    this.lastSyncedAt,
    this.compact = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = (syncStatus ?? '').trim().isEmpty
        ? 'local_only'
        : syncStatus!.trim();

    final config = switch (normalized) {
      'synced' => (
          label: 'Synced',
          bg: const Color(0xFFEAF4EF),
          fg: const Color(0xFF1E6B3A),
          icon: Icons.cloud_done_rounded,
        ),
      'pending_upload' => (
          label: 'Pending',
          bg: const Color(0xFFFFF4DB),
          fg: const Color(0xFF8A5A00),
          icon: Icons.cloud_upload_rounded,
        ),
      _ => (
          label: 'Local only',
          bg: const Color(0xFFF2F3F5),
          fg: const Color(0xFF495057),
          icon: Icons.phone_android_rounded,
        ),
    };

    final vertical = compact ? 4.0 : 6.0;
    final horizontal = compact ? 8.0 : 10.0;
    final iconSize = compact ? 14.0 : 16.0;
    final fontSize = compact ? 11.5 : 12.5;

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      ),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: iconSize, color: config.fg),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: TextStyle(
              color: config.fg,
              fontWeight: FontWeight.w800,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );

    return Tooltip(
      message: lastSyncedAt != null && lastSyncedAt!.isNotEmpty
          ? 'Last synced: $lastSyncedAt'
          : config.label,
      child: onTap == null
          ? badge
          : Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onTap,
                child: badge,
              ),
            ),
    );
  }
}
