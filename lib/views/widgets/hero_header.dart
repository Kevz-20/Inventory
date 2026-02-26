import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class HeroHeader extends StatelessWidget {
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
  Widget build(BuildContext context) {
    const double sideSlot = 40; // space for back/bell alignment
    const double logoSize = 40; // ✅ change this freely; title won't shift
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 18),
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
          // ✅ TOP AREA uses Stack so logo doesn't affect centering
          SizedBox(
            height: 40, // fixed height for consistent alignment
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Row keeps back + title + bell alignment
                Row(
                  children: [
                    SizedBox(
                      width: sideSlot,
                      child: showBack
                          ? InkWell(
                              onTap: onBackTap,
                              borderRadius: BorderRadius.circular(14),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 20,
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
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: sideSlot,
                      child: InkWell(
                        onTap: onBellTap,
                        borderRadius: BorderRadius.circular(14),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ✅ Logo overlay (does NOT take Row space)
                if (showLogo)
                  Positioned(
                    left: 8, // beside back slot area
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

          const SizedBox(height: 14),

          // ✅ Balance glass card (unchanged)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Cash on Hand",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        balance,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Mobile Number: $mobileNumber",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.80),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onEyeTap,
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.visibility_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}