// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class Notification3DCard extends StatelessWidget {
  static const Color _cardStart = Color(0xFFF6FBF9);
  static const Color _cardEnd = Color(0xFFEAF6F2);
  static const Color _cardBorder = Color(0xFFBFDCD4);
  static const Color _titleColor = Color(0xFF0B3D35);
  static const Color _messageColor = Color(0xFF244E47);
  static const Color _mutedColor = Color(0xFF3E6A62);

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
    final effectiveBadgeColor = badgeColor ?? AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_cardStart, _cardEnd],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.65),
                blurRadius: 10,
                offset: const Offset(-2, -2),
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
                              color: effectiveBadgeColor.withOpacity(0.18),
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
                            Icons.schedule_rounded,
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
