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
  const double sideSlot = 40;
  const double logoSize = 40;

  final topInset = MediaQuery.of(context).padding.top;

  return Container(
    width: double.infinity,

    // ✅ responsive top padding (instead of fixed 52)
    padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 18),

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
          height: 40,
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
                      alignment:
                          centerTitle ? Alignment.center : Alignment.centerLeft,

                      // ✅ prevents title overflow when textScale is big
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
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

              if (showLogo)
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

        const SizedBox(height: 14),

        // ✅ your improved 3D card stays the same
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
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
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.28),
              width: 1.4,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Cash on Hand",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      balance,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Mobile Number: $mobileNumber",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onEyeTap,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.35),
                        Colors.white.withOpacity(0.20),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 16,
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
        ),
      ],
    ),
  );
}
}