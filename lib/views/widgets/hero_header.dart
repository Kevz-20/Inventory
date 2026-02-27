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
          // ✅ Readable 3D Card (Senior-friendly)
Container(
  width: double.infinity,
  padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),

    // less transparent = clearer for older eyes
    color: Colors.white.withOpacity(0.16),

    // ✅ OUTER SHADOW (3D lift)
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.25),
        blurRadius: 22,
        offset: const Offset(0, 14),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.12),
        blurRadius: 10,
        offset: const Offset(0, 6),
      ),
    ],

    // ✅ border definition
    border: Border.all(
      color: Colors.white.withOpacity(0.22),
      width: 1.3,
    ),
  ),
  child: Stack(
    children: [
      // ✅ TOP HIGHLIGHT (inner shine)
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.28),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),

      // ✅ subtle inner bottom shadow (makes it feel “pressed in”)
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          height: 26,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.12),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),

      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Cash on Hand",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),

                // ✅ amount — biggest + tight
                Text(
                  balance,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  "Mobile Number: $mobileNumber",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // ✅ Floating “eye” control (more 3D, easier tap)
          InkWell(
            onTap: onEyeTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.visibility_outlined,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    ],
  ),
),
        ],
      ),
    );
  }
}