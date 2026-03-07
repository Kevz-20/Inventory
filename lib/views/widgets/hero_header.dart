// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../../providers/unread_notif_count_provider.dart';

class HeroHeader extends ConsumerWidget {
  final String title;
  final String balance;
  final String mobileNumber;
  final VoidCallback onBellTap;
  final VoidCallback onEyeTap;

  final bool showBack;
  final VoidCallback? onBackTap;

  final bool centerTitle;
  final bool showLogo;

  const HeroHeader({
    super.key,
    required this.title,
    required this.balance,
    required this.mobileNumber,
    required this.onBellTap,
    required this.onEyeTap,
    this.showBack = false,
    this.onBackTap,
    this.centerTitle = false,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topInset = MediaQuery.of(context).padding.top;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        // ✅ SCALE FACTOR (phone → tablet)
        // 360 = small phone baseline, 900 = tablet cap
        final s = (w / 360).clamp(1.0, 1.35);

        // ✅ Responsive sizes (same layout)
        final sideSlot = (40 * s).clamp(40.0, 54.0);
        final logoSize = (40 * s).clamp(40.0, 54.0);
        final topRowHeight = (40 * s).clamp(40.0, 56.0);

        final padH = (16 * s).clamp(16.0, 22.0);
        final padTop = (topInset + 12 * s).clamp(topInset + 12, topInset + 20);
        final padBottom = (18 * s).clamp(18.0, 24.0);

        final titleSize = (22 * s).clamp(22.0, 28.0);
        final cashLabelSize = (15 * s).clamp(15.0, 18.0);
        final balanceSize = (36 * s).clamp(32.0, 46.0);
        final mobileSize = (14.5 * s).clamp(14.0, 17.0);

        final cardRadius = (22 * s).clamp(22.0, 28.0);
        final eyePad = (12 * s).clamp(12.0, 16.0);
        final eyeIconSize = (26 * s).clamp(24.0, 30.0);

        // ✅ Avoid logo overlapping title on very small width
        final showLogoSafe = showLogo && w >= 360;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(padH, padTop, padH, padBottom),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.headerTop, AppColors.headerBottom],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: topRowHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: sideSlot,
                          child: showBack
                              ? InkWell(
                                  onTap: onBackTap,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Padding(
                                    padding: EdgeInsets.all((6 * s).clamp(6.0, 10.0)),
                                    child: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Colors.white,
                                      size: (20 * s).clamp(20.0, 24.0),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        Expanded(
                          child: Align(
                            alignment: centerTitle
                                ? Alignment.center
                                : Alignment.centerLeft,
                            child: Padding(
                              // ✅ if logo is shown, add a tiny left padding so title won't collide
                              padding: EdgeInsets.only(
                                left: showLogoSafe ? (logoSize + 10) : 0,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: centerTitle
                                    ? Alignment.center
                                    : Alignment.centerLeft,
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ✅ BELL WITH BADGE
                        SizedBox(
                          width: sideSlot,
                          child: InkWell(
                            onTap: onBellTap,
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: EdgeInsets.all((6 * s).clamp(6.0, 10.0)),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    Icons.notifications_none_rounded,
                                    color: Colors.white,
                                    size: (26 * s).clamp(26.0, 32.0),
                                  ),
                                  ref.watch(unreadNotifCountProvider).when(
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, _) => const SizedBox.shrink(),
                                    data: (count) {
                                      if (count <= 0) return const SizedBox.shrink();
                                      return Positioned(
                                        right: -6,
                                        top: -6,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal:
                                                (6 * s).clamp(6.0, 9.0),
                                            vertical:
                                                (2 * s).clamp(2.0, 4.0),
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: Text(
                                            count > 99 ? '99+' : '$count',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize:
                                                  (10.5 * s).clamp(10.5, 13.0),
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (showLogoSafe)
                      Positioned(
                        left: 8,
                        child: Image.asset(
                          'lib/assets/logo.png',
                          height: logoSize,
                          width: logoSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: (14 * s).clamp(14.0, 20.0)),

              // ✅ 3D card (same style, responsive sizes)
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  (20 * s).clamp(20.0, 28.0),
                  (18 * s).clamp(18.0, 24.0),
                  (16 * s).clamp(16.0, 22.0),
                  (18 * s).clamp(18.0, 24.0),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cardRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.30),
                      Colors.white.withOpacity(0.18),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: (24 * s).clamp(24.0, 32.0),
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: (10 * s).clamp(10.0, 16.0),
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.28),
                    width: (1.4 * s).clamp(1.4, 1.8),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Cash on Hand",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: cashLabelSize,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: (10 * s).clamp(10.0, 14.0)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              balance,
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: balanceSize,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                          ),
                          SizedBox(height: (12 * s).clamp(12.0, 16.0)),
                          Text(
                            "Mobile Number: $mobileNumber",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: mobileSize,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: onEyeTap,
                      borderRadius: BorderRadius.circular(
                        (18 * s).clamp(18.0, 22.0),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(eyePad),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.35),
                              Colors.white.withOpacity(0.20),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            (18 * s).clamp(18.0, 22.0),
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: (16 * s).clamp(16.0, 22.0),
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.visibility_outlined,
                          color: Colors.white,
                          size: eyeIconSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
