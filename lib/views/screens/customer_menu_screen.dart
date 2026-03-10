// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app_router.dart';
import '../../core/app_colors.dart';
import '../../view_models/home_view_model.dart';
import '../widgets/hero_header.dart';
import '../widgets/nav_bar.dart';

class CustomerMenuScreen extends ConsumerStatefulWidget {
  const CustomerMenuScreen({super.key});

  @override
  ConsumerState<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends ConsumerState<CustomerMenuScreen>
    with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider.notifier).fetchHomeData();
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    ref.read(homeViewModelProvider.notifier).fetchHomeData();
  }

  Size _screenSize(BuildContext context) => MediaQuery.of(context).size;

  double _screenWidth(BuildContext context) => _screenSize(context).width;

  double _screenHeight(BuildContext context) => _screenSize(context).height;

  bool _isTablet(BuildContext context) => _screenWidth(context) >= 700;

  bool _isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  bool _isShortScreen(BuildContext context) => _screenHeight(context) < 500;

  bool _useSplitLayout(BuildContext context) {
    final width = _screenWidth(context);
    final height = _screenHeight(context);
    return width >= 900 && height >= 560;
  }

  double _responsiveScale(BuildContext context) {
    final width = _screenWidth(context);
    if (width < 360) return 0.88;
    if (width < 400) return 0.94;
    if (width < 700) return 1.00;
    if (width < 1000) return 1.10;
    return 1.18;
  }

  double _r(BuildContext context, double value) {
    final scaled = value * _responsiveScale(context);
    final min = value * 0.82;
    final max = value * 1.28;
    return scaled.clamp(min, max);
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);

    final pesoFormatter = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '\u20B1 ',
      decimalDigits: 2,
    );

    final balanceText = pesoFormatter.format(homeState.cashOnHand);
    final mobileText = homeState.mobileNumber ?? 'Not set';

    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final isShortScreen = _isShortScreen(context);
    final useSplitLayout = _useSplitLayout(context);

    final maxContentWidth = useSplitLayout
        ? 1240.0
        : isTablet
            ? 780.0
            : double.infinity;

    final horizontalPadding = useSplitLayout
        ? 24.0
        : isTablet
            ? 18.0
            : isLandscape
                ? 14.0
                : 16.0;

    final verticalPadding = useSplitLayout
        ? 14.0
        : isShortScreen
            ? 8.0
            : isLandscape
                ? 10.0
                : 12.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeroHeader(
              title: 'Customer',
              balance: homeState.isMoneyVisible
                  ? balanceText
                  : '\u20B1 \u2022\u2022\u2022\u2022\u2022',
              mobileNumber: mobileText,
              centerTitle: true,
              showBack: true,
              onBackTap: () => context.go('/home'),
              onBellTap: () => context.push('/notifications'),
              onEyeTap: () => ref
                  .read(homeViewModelProvider.notifier)
                  .toggleMoneyVisibility(),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      verticalPadding,
                      horizontalPadding,
                      verticalPadding,
                    ),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final h = c.maxHeight;
                        final w = c.maxWidth;

                        final gap = useSplitLayout
                            ? (math.min(w, h) * 0.022).clamp(12.0, 18.0)
                            : isShortScreen
                                ? 10.0
                                : isLandscape
                                    ? (h * 0.022).clamp(8.0, 12.0)
                                    : (h * 0.026).clamp(10.0, 16.0);

                        if (isLandscape && isShortScreen && !isTablet) {
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                SizedBox(
                                  height: _r(context, 108),
                                  child: _homeBigActionTile(
                                    label: 'HALIN',
                                    subtitle: 'Record cash sales',
                                    icon: Icons.point_of_sale_outlined,
                                    onTap: () => context.push('/record_sales'),
                                  ),
                                ),
                                SizedBox(height: gap),
                                SizedBox(
                                  height: _r(context, 108),
                                  child: _homeBigActionTile(
                                    label: 'CUSTOMER UTANG',
                                    subtitle: 'Manage customer credit',
                                    icon: Icons.receipt_long_outlined,
                                    onTap: () => context.push('/customer_utang'),
                                  ),
                                ),
                                SizedBox(height: gap),
                                SizedBox(
                                  height: _r(context, 250),
                                  child: _TopSellingProductsPanel(
                                    products: homeState.topSellingProducts,
                                    loading: homeState.isTopProductsLoading,
                                    error: homeState.topProductsError,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (useSplitLayout) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 11,
                                child: _buildTilesPanel(context: context, gap: gap),
                              ),
                              SizedBox(width: gap),
                              Expanded(
                                flex: 13,
                                child: _TopSellingProductsPanel(
                                  products: homeState.topSellingProducts,
                                  loading: homeState.isTopProductsLoading,
                                  error: homeState.topProductsError,
                                ),
                              ),
                            ],
                          );
                        }

                        final tilesBlock = isTablet
                            ? (isLandscape
                                ? (h * 0.36).clamp(220.0, 300.0)
                                : (h * 0.40).clamp(280.0, 380.0))
                            : (isLandscape
                                ? (h * 0.42).clamp(190.0, 260.0)
                                : (h * 0.34).clamp(220.0, 320.0));

                        return Column(
                          children: [
                            SizedBox(
                              height: tilesBlock,
                              child: _buildTilesPanel(context: context, gap: gap),
                            ),
                            SizedBox(height: gap),
                            Expanded(
                              child: _TopSellingProductsPanel(
                                products: homeState.topSellingProducts,
                                loading: homeState.isTopProductsLoading,
                                error: homeState.topProductsError,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: homeState.selectedIndex,
        noHighlight: true,
      ),
    );
  }

  Widget _buildTilesPanel({
    required BuildContext context,
    required double gap,
  }) {
    return Column(
      children: [
        Expanded(
          child: _homeBigActionTile(
            label: 'HALIN',
            subtitle: 'Record cash sales',
            icon: Icons.point_of_sale_outlined,
            onTap: () => context.push('/record_sales'),
          ),
        ),
        SizedBox(height: gap),
        Expanded(
          child: _homeBigActionTile(
            label: 'CUSTOMER UTANG',
            subtitle: 'Manage customer credit',
            icon: Icons.receipt_long_outlined,
            onTap: () => context.push('/customer_utang'),
          ),
        ),
      ],
    );
  }

  Widget _homeBigActionTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(_r(context, 22));
    final isHalin = label.toUpperCase().contains('HALIN');
    final startColor =
        isHalin ? const Color(0xFFEAF7F3) : const Color(0xFFE6F3F0);
    final endColor =
        isHalin ? const Color(0xFFD8EEE8) : const Color(0xFFD0E9E3);
    const primaryTextColor = Color(0xFF0B3D35);
    const secondaryTextColor = Color(0xFF2F5C54);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, c) {
            final h = c.maxHeight;
            final w = c.maxWidth;
            final isLandscape = _isLandscape(context);
            final isTablet = _isTablet(context);
            final compact = h < 120 || w < 320;

            final iconSize = compact
                ? (h * 0.22).clamp(_r(context, 22), _r(context, 30))
                : isTablet
                    ? (h * 0.24).clamp(_r(context, 28), _r(context, 40))
                    : (h * 0.28).clamp(_r(context, 26), _r(context, 34));

            final iconBox = compact
                ? (h * 0.42).clamp(_r(context, 42), _r(context, 56))
                : isTablet
                    ? (h * 0.56).clamp(_r(context, 56), _r(context, 82))
                    : (h * 0.60).clamp(_r(context, 54), _r(context, 74));

            final titleSize = compact
                ? (h * 0.15).clamp(_r(context, 15), _r(context, 18))
                : isLandscape
                    ? (h * 0.17).clamp(_r(context, 17), _r(context, 22))
                    : (h * 0.18).clamp(_r(context, 18), _r(context, 22));

            final subSize = compact
                ? (h * 0.10).clamp(_r(context, 10.5), _r(context, 12.5))
                : isLandscape
                    ? (h * 0.12).clamp(_r(context, 12), _r(context, 14.5))
                    : (h * 0.13).clamp(_r(context, 12.5), _r(context, 15));

            final vPad = compact
                ? (h * 0.08).clamp(_r(context, 8), _r(context, 12))
                : isLandscape
                    ? (h * 0.10).clamp(_r(context, 10), _r(context, 16))
                    : (h * 0.12).clamp(_r(context, 12), _r(context, 18));

            final accentHeight = compact
                ? (h * 0.35).clamp(_r(context, 32), _r(context, 44))
                : isLandscape
                    ? (h * 0.50).clamp(_r(context, 42), _r(context, 60))
                    : (h * 0.55).clamp(_r(context, 48), _r(context, 64));

            final horizontalPad = compact ? _r(context, 12) : _r(context, 18);
            final gapBetween = compact ? _r(context, 10) : _r(context, 16);

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPad,
                vertical: vPad,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [startColor, endColor],
                ),
                borderRadius: radius,
                border: Border.all(color: const Color(0xFFBFDCD4), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0C4B3E).withOpacity(0.18),
                    blurRadius: _r(context, 16),
                    offset: Offset(0, _r(context, 8)),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.80),
                    blurRadius: _r(context, 5),
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: _r(context, compact ? 4 : 5),
                    height: accentHeight * 0.9,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  SizedBox(width: gapBetween),
                  Container(
                    width: iconBox,
                    height: iconBox,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.96),
                          Colors.white.withOpacity(0.82),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(_r(context, 18)),
                      border: Border.all(color: const Color(0xFFB4D8CF)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0C4B3E).withOpacity(0.16),
                          blurRadius: _r(context, 8),
                          offset: Offset(0, _r(context, 3)),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primary,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: gapBetween),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w900,
                              color: primaryTextColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        SizedBox(height: _r(context, compact ? 4 : 6)),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: subSize,
                            fontWeight: FontWeight.w700,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: _r(context, compact ? 8 : 10)),
                  Container(
                    width: _r(context, compact ? 32 : 38),
                    height: _r(context, compact ? 32 : 38),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFB4D8CF)),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primary,
                      size: _r(context, compact ? 18 : 20),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopSellingProductsPanel extends StatelessWidget {
  const _TopSellingProductsPanel({
    required this.products,
    required this.loading,
    required this.error,
  });

  final List<TopSellingProduct> products;
  final bool loading;
  final String? error;

  bool _isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 700;

  bool _isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  double _responsiveScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 0.88;
    if (width < 400) return 0.94;
    if (width < 700) return 1.00;
    if (width < 1000) return 1.10;
    return 1.18;
  }

  double _r(BuildContext context, double value) {
    final scaled = value * _responsiveScale(context);
    final min = value * 0.82;
    final max = value * 1.28;
    return scaled.clamp(min, max);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);

    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        final compact = h < 220;

        return Container(
          padding: EdgeInsets.fromLTRB(
            _r(context, compact ? 10 : 14),
            _r(context, compact ? 10 : 14),
            _r(context, compact ? 10 : 14),
            _r(context, compact ? 8 : 10),
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF5FAF8)],
            ),
            borderRadius: BorderRadius.circular(_r(context, 18)),
            border: Border.all(color: const Color(0xFFD4E8E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: _r(context, 14),
                offset: Offset(0, _r(context, 8)),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: _r(context, compact ? 24 : 30),
                    height: _r(context, compact ? 24 : 30),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C6A57).withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: const Color(0xFF0C6A57),
                      size: _r(context, compact ? 14 : 17),
                    ),
                  ),
                  SizedBox(width: _r(context, 8)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top Selling Products',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact
                                ? _r(context, 13)
                                : isTablet
                                    ? _r(context, 16)
                                    : _r(context, 15),
                            fontWeight: FontWeight.w900,
                            color: Colors.black.withOpacity(0.82),
                          ),
                        ),
                        SizedBox(height: _r(context, 1)),
                        Text(
                          'Ranked by quantity sold',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: _r(context, compact ? 8.8 : 10),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5D7D76),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: _r(context, compact ? 82 : 104),
                    child: Text(
                      'Units Sold',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: _r(context, compact ? 9.5 : 11),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0C6A57),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: _r(context, compact ? 8 : 12)),
              Container(
                height: 1,
                color: const Color(0xFFD4E8E1),
              ),
              SizedBox(height: _r(context, compact ? 8 : 10)),
              Expanded(
                child: _buildContent(
                  context,
                  compact: compact || (isLandscape && h < 260),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, {required bool compact}) {
    if (loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Text(
          'Unable to load top products.',
          style: TextStyle(
            color: Colors.black.withOpacity(0.55),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Text(
          'No sales yet. Top products will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black.withOpacity(0.55),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final topUnits = products.first.unitsSold <= 0 ? 1 : products.first.unitsSold;

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: products.length,
      separatorBuilder: (_, _) => SizedBox(height: _r(context, compact ? 7 : 10)),
      itemBuilder: (context, i) {
        final product = products[i];
        final ratio = (product.unitsSold / topUnits).clamp(0.0, 1.0);

        return Container(
          padding: EdgeInsets.all(_r(context, compact ? 8 : 11)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFFDFEFE)],
            ),
            borderRadius: BorderRadius.circular(_r(context, 14)),
            border: Border.all(color: const Color(0xFFE1EEE9)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0C4B3E).withOpacity(0.06),
                blurRadius: _r(context, 7),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _rankBadge(context, i + 1, compact: compact),
              SizedBox(width: _r(context, compact ? 8 : 10)),
              _productImage(context, product, compact: compact),
              SizedBox(width: _r(context, compact ? 8 : 10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _r(context, compact ? 12.5 : 14),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF123B34),
                      ),
                    ),
                    SizedBox(height: _r(context, compact ? 4 : 6)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: _r(context, compact ? 5 : 6),
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: const Color(0xFFE4F0EC),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF0C6A57),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: _r(context, compact ? 6 : 8)),
              SizedBox(
                width: _r(context, compact ? 82 : 104),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${product.unitsSold}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: _r(context, compact ? 12.5 : 15),
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0C6A57),
                      ),
                    ),
                    Text(
                      'units',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: _r(context, compact ? 9 : 10),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5D7D76),
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

  Widget _rankBadge(BuildContext context, int rank, {required bool compact}) {
    final size = _r(context, compact ? 25 : 31);
    final color = _rankAccentColor(rank);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.48)),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          fontSize: _r(context, compact ? 8.6 : 10.5),
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Color _rankAccentColor(int rank) {
    if (rank == 1) return const Color(0xFFB07A00);
    if (rank == 2) return const Color(0xFF5A6C8A);
    if (rank == 3) return const Color(0xFF9A5E2C);
    return const Color(0xFF0C6A57);
  }

  Widget _productImage(
    BuildContext context,
    TopSellingProduct product, {
    required bool compact,
  }) {
    final imageRef = _resolveImageRef(product);
    final size = _r(context, compact ? 34 : 46);

    if (imageRef == null) {
      return _fallbackImage(context, compact: compact);
    }

    if (imageRef.isFile) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(_r(context, 10)),
        child: Image.file(
          File(imageRef.path),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackImage(context, compact: compact),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(_r(context, 10)),
      child: Image.asset(
        imageRef.path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackImage(context, compact: compact),
      ),
    );
  }

  _ImageRef? _resolveImageRef(TopSellingProduct product) {
    final raw = product.imagePath?.trim();
    if (raw == null || raw.isEmpty) return null;

    if (raw.startsWith('file://')) {
      final filePath = raw.replaceFirst('file://', '');
      if (filePath.isNotEmpty) {
        return _ImageRef(path: filePath, isFile: true);
      }
    }

    if (_looksLikeFilePath(raw)) {
      return _ImageRef(path: raw, isFile: true);
    }

    if (raw.startsWith('lib/assets/')) {
      return _ImageRef(path: raw, isFile: false);
    }

    final normalized = raw.replaceAll('\\', '/');
    const marker = 'product_images/';
    final markerIndex = normalized.lastIndexOf(marker);
    if (markerIndex >= 0) {
      final fileName = normalized.substring(markerIndex + marker.length);
      if (fileName.isNotEmpty) {
        return _ImageRef(
          path: 'lib/assets/product_images/$fileName',
          isFile: false,
        );
      }
    }

    return null;
  }

  bool _looksLikeFilePath(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.startsWith('/') ||
        normalized.startsWith('./') ||
        RegExp(r'^[A-Za-z]:[/\\]').hasMatch(path);
  }

  Widget _fallbackImage(BuildContext context, {required bool compact}) {
    final size = _r(context, compact ? 34 : 46);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE6F2EE),
        borderRadius: BorderRadius.circular(_r(context, 10)),
        border: Border.all(color: const Color(0xFFCAE4DC)),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: const Color(0xFF0C6A57),
        size: _r(context, compact ? 17 : 21),
      ),
    );
  }
}

class _ImageRef {
  const _ImageRef({required this.path, required this.isFile});

  final String path;
  final bool isFile;
}
