import 'package:flutter/material.dart';

class DashboardBackground extends StatelessWidget {
  const DashboardBackground({super.key});

  double _scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / 390).clamp(0.84, 1.18);
  }

  double _r(BuildContext context, double value) => value * _scale(context);

  bool _isVeryNarrowPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < 380;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8F9FF),
              Color(0xFFF1F4FF),
              Color(0xFFF9FBFF),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -_r(context, 60),
              right: -_r(context, 40),
              child: _BlurOrb(
                size: _r(
                  context,
                  _isVeryNarrowPhone(context) ? 160 : 220,
                ),
                colors: const [Color(0xFF52C7EA), Color(0x330E5BFF)],
              ),
            ),
            Positioned(
              top: _r(context, 520),
              left: -_r(context, 90),
              child: _BlurOrb(
                size: _r(context, 220),
                colors: const [Color(0x33648DFF), Color(0x11FFFFFF)],
              ),
            ),
            Positioned(
              right: -_r(context, 40),
              bottom: _r(context, 110),
              child: _DotField(size: _isVeryNarrowPhone(context) ? _r(context, 110) : _r(context, 170)),
            ),
            Positioned(
              left: -_r(context, 20),
              right: -_r(context, 20),
              bottom: _r(context, 70),
              child: SizedBox(
                height: _r(context, 130),
                child: IgnorePointer(
                  child: CustomPaint(
                    size: Size(double.infinity, _r(context, 130)),
                    painter: const _BackgroundWavePainter(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({
    required this.size,
    required this.colors,
  });

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class _DotField extends StatelessWidget {
  const _DotField({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DotsPainter()),
    );
  }
}

class _BackgroundWavePainter extends CustomPainter {
  const _BackgroundWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = const Color(0x3D89B2FF);
    final paint2 = Paint()..color = const Color(0x26DCEAFF);

    final path1 = Path()
      ..moveTo(0, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.20,
        size.height * 0.28,
        size.width * 0.48,
        size.height * 0.60,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.88,
        size.width,
        size.height * 0.45,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final path2 = Path()
      ..moveTo(0, size.height * 0.76)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.48,
        size.width * 0.66,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.96,
        size.width,
        size.height * 0.68,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFCFD8F8);
    final gap = size.width / 12;

    for (double y = gap * 0.6; y < size.height; y += gap) {
      for (double x = gap * 0.4; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.7, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
