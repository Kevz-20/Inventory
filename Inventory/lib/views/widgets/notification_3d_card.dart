// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// Renamed alias kept for backward-compat — use [NotificationCard] in new code.
typedef Notification3DCard = NotificationCard;

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.icon,
    required this.badgeText,
    required this.accentColor,
    required this.title,
    required this.message,
    required this.timeText,
    required this.onTap,
    this.dueText,
  });

  final IconData  icon;
  final String    badgeText;
  final Color     accentColor;
  final String    title;
  final String    message;
  final String    timeText;
  final String?   dueText;
  final VoidCallback onTap;

  // Responsive helper
  double _r(BuildContext context, double v) {
    final w = MediaQuery.of(context).size.width;
    return v * (w / 390).clamp(0.85, 1.15);
  }

  @override
  Widget build(BuildContext context) {
    double r(double v) => _r(context, v);

    // Light tinted backgrounds derived from the accent colour
    final iconBg     = accentColor.withOpacity(0.10);
    final badgeBg    = accentColor.withOpacity(0.10);
    final badgeBorder = accentColor.withOpacity(0.28);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(r(20)),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(r(20)),
            border: Border.all(color: const Color(0xFFCDD5EE), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B3A7A).withOpacity(0.07),
                blurRadius: r(14),
                offset: Offset(0, r(4)),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left accent bar (colour-coded by type) ─────────────────
              Container(
                width: r(5),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.only(
                    topLeft:    Radius.circular(r(20)),
                    bottomLeft: Radius.circular(r(20)),
                  ),
                ),
              ),

              // ── Card body ──────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(r(14), r(14), r(14), r(14)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon container
                      Container(
                        width: r(48), height: r(48),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(r(14)),
                          border: Border.all(
                              color: accentColor.withOpacity(0.22), width: 1.5),
                        ),
                        child: Icon(icon, color: accentColor, size: r(24)),
                      ),
                      SizedBox(width: r(12)),

                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Title + badge row ───────────────────────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: r(15),
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF1B3A7A),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                SizedBox(width: r(8)),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: r(9), vertical: r(4)),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius:
                                        BorderRadius.circular(r(999)),
                                    border: Border.all(
                                        color: badgeBorder, width: 1),
                                  ),
                                  child: Text(
                                    badgeText,
                                    style: TextStyle(
                                      fontSize: r(10.5),
                                      fontWeight: FontWeight.w900,
                                      color: accentColor,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: r(7)),

                            // ── Message ─────────────────────────────────
                            Text(
                              message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: r(13.5),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF425983),
                                height: 1.4,
                              ),
                            ),

                            SizedBox(height: r(10)),

                            // ── Time row ────────────────────────────────
                            Row(children: [
                              Icon(Icons.schedule_rounded,
                                  size: r(13),
                                  color: const Color(0xFF5B6D96)),
                              SizedBox(width: r(5)),
                              Expanded(
                                child: Text(
                                  timeText,
                                  style: TextStyle(
                                    fontSize: r(12),
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF5B6D96),
                                  ),
                                ),
                              ),
                            ]),

                            // ── Due date row (optional) ──────────────────
                            if (dueText != null) ...[
                              SizedBox(height: r(6)),
                              Row(children: [
                                Icon(Icons.event_note_rounded,
                                    size: r(13),
                                    color: const Color(0xFF5B6D96)),
                                SizedBox(width: r(5)),
                                Expanded(
                                  child: Text(
                                    dueText!,
                                    style: TextStyle(
                                      fontSize: r(12),
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF5B6D96),
                                    ),
                                  ),
                                ),
                              ]),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ), // IntrinsicHeight
        ),
      ),
    );
  }
}
