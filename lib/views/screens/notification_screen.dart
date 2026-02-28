import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../../models/notification_item.dart';
import '../../providers/notification_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  IconData _iconFor(AppNotifType type) {
    switch (type) {
      case AppNotifType.ownerPayableSoon:
        return Icons.event_available_rounded;
      case AppNotifType.customerUtangDueToday:
        return Icons.warning_amber_rounded;
      case AppNotifType.lowStock:
        return Icons.inventory_2_rounded;
    }
  }

  String _badgeText(AppNotifType type) {
    switch (type) {
      case AppNotifType.ownerPayableSoon:
        return 'PAYABLE';
      case AppNotifType.customerUtangDueToday:
        return 'DUE TODAY';
      case AppNotifType.lowStock:
        return 'LOW STOCK';
    }
  }

  // ✅ For nicer badge tone per type (still within theme)
  double _badgeOpacity(AppNotifType type) {
    switch (type) {
      case AppNotifType.customerUtangDueToday:
        return 0.18;
      case AppNotifType.ownerPayableSoon:
        return 0.14;
      case AppNotifType.lowStock:
        return 0.12;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,

      // ✅ Green themed header like your HeroHeader
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
            child: Text(
              'Error: $e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
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
                        color: AppColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.22),
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
                        color: Colors.black.withOpacity(0.75),
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You’re all caught up.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.50),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            // ✅ better refresh behavior
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              await ref.read(notificationsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final n = items[i];

                return _Notification3DCard(
                  icon: _iconFor(n.type),
                  badgeText: _badgeText(n.type),
                  badgeOpacity: _badgeOpacity(n.type),
                  title: n.title,
                  message: n.message,
                  dueText: n.dueDate == null
                      ? null
                      : 'Due: ${n.dueDate!.toLocal().toString().split(" ").first}',
                  onTap: () {
                    // Later: open owner utang / customer utang / product detail
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

// ===================== 3D NOTIFICATION CARD =====================

class _Notification3DCard extends StatelessWidget {
  final IconData icon;
  final String badgeText;
  final double badgeOpacity;
  final String title;
  final String message;
  final String? dueText;
  final VoidCallback onTap;

  const _Notification3DCard({
    required this.icon,
    required this.badgeText,
    required this.badgeOpacity,
    required this.title,
    required this.message,
    required this.onTap,
    this.dueText,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: radius,

            // ✅ Professional glass + 3D feel
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.88),
              ],
            ),

            // ✅ Stronger shadow (3D)
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],

            // ✅ crisp border for “premium card”
            border: Border.all(
              color: Colors.black.withOpacity(0.06),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Icon bubble
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.18),
                      AppColors.primary.withOpacity(0.08),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.18),
                  ),
                ),
                child: Icon(icon, color: AppColors.primary, size: 26),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15.8,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(badgeOpacity),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.18),
                            ),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11.2,
                              color: AppColors.primary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      message,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.72),
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),

                    if (dueText != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: Colors.black.withOpacity(0.45),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dueText!,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.52),
                                fontWeight: FontWeight.w700,
                                fontSize: 12.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}