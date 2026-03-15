// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class Notification3DCard extends StatelessWidget {
  static const Color _cardStart = Color(0xFFFDFEFF);
  static const Color _cardEnd = Color(0xFFF3F7FF);
  static const Color _cardBorder = Color(0xFFDDE5F8);
  static const Color _titleColor = Color(0xFF213A6B);
  static const Color _messageColor = Color(0xFF425983);
  static const Color _mutedColor = Color(0xFF60739B);
  static const Color _accentBlue = Color(0xFF2F6BFF);

  final IconData icon;
  final String badgeText;
  final double badgeOpacity;
  final Color? badgeColor;
  final String title;
  final String message;
  final String createdAtText;
  final String? dueText;
  final VoidCallback onTap;

  const Notification3DCard({
    super.key,
    required this.icon,
    required this.badgeText,
    required this.badgeOpacity,
    this.badgeColor,
    required this.title,
    required this.message,
    required this.createdAtText,
    required this.onTap,
    this.dueText,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    final effectiveBadgeColor = badgeColor ?? _accentBlue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_cardStart, _cardEnd],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF93A4CF).withOpacity(0.16),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: _cardBorder, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFECF3FF),
                      Color(0xFFD8E8FF),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFCFE0FF),
                  ),
                ),
                child: Icon(icon, color: _accentBlue, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15.8,
                              color: _titleColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: effectiveBadgeColor.withOpacity(badgeOpacity),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: effectiveBadgeColor.withOpacity(0.22),
                            ),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11.2,
                              color: effectiveBadgeColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _messageColor,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: _mutedColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            createdAtText,
                            style: TextStyle(
                              color: _mutedColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (dueText != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.event_note_rounded,
                            size: 16,
                            color: _mutedColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dueText!,
                              style: TextStyle(
                                color: _mutedColor,
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
