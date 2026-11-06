import 'package:flutter/material.dart';
import 'package:rendzu/core/theme/app_theme.dart';

/// Заставка: анимированный логотип (камень падает на доску, появляется
/// название), затем переход в главное меню.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _stoneDrop;
  late final Animation<double> _titleFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _stoneDrop = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
    );
    _titleFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
    );
    _ctrl.forward().then((_) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/menu');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cream, AppColors.creamDark],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Анимированный камень + мини-доска
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // мини-доска 3×3
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.woodMid,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _MiniBoardPainter(),
                      ),
                    ),
                    // падающий камень
                    AnimatedBuilder(
                      animation: _stoneDrop,
                      builder: (context, child) {
                        final dy = (1 - _stoneDrop.value) * -120;
                        return Transform.translate(
                          offset: Offset(0, dy),
                          child: child,
                        );
                      },
                      child: _GlossyStone(
                        size: 56,
                        color: AppColors.stoneBlack,
                        highlight: AppColors.stoneBlackHi,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _titleFade,
                child: Column(
                  children: const [
                    Text(
                      'Рэндзю',
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'для Дианы',
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.coral,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(AppColors.coral.withOpacity(0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.woodLine
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    // 3 линии × 3 линии → рисуем сетку 3×3
    const n = 3;
    final step = size.width / (n + 1);
    for (var i = 1; i <= n; i++) {
      final p = step * i;
      canvas.drawLine(Offset(p, step), Offset(p, size.height - step), paint);
      canvas.drawLine(Offset(step, p), Offset(size.width - step, p), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Объёмный камень с бликом.
class _GlossyStone extends StatelessWidget {
  const _GlossyStone({
    required this.size,
    required this.color,
    required this.highlight,
  });
  final double size;
  final Color color;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.9,
          colors: [highlight, color],
          stops: const [0.0, 0.7],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
    );
  }
}
