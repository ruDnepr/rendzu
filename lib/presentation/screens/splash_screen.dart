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
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Анимированный камень + мини-доска — крупный логотип
              SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // мини-доска 5×5
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.woodLight,
                            AppColors.woodMid,
                            AppColors.woodDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 18,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _MiniBoardPainter(),
                      ),
                    ),
                    // падающий камень — крупный
                    AnimatedBuilder(
                      animation: _stoneDrop,
                      builder: (context, child) {
                        final dy = (1 - _stoneDrop.value) * -150;
                        return Transform.translate(
                          offset: Offset(0, dy),
                          child: child,
                        );
                      },
                      child: _GlossyStone(
                        size: 78,
                        color: AppColors.stoneBlack,
                        highlight: AppColors.stoneBlackHi,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _titleFade,
                child: Column(
                  children: const [
                    Text(
                      'Рэндзю',
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'для Дианы',
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.coral,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Пять камней в ряд — и победа!',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        color: AppColors.textMid,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.coral),
                ),
              ),
              const Spacer(flex: 1),
              const Text(
                'версия 1.0',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 16),
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
    // Сетка 5×5 — как настоящая доска рэндзю
    const n = 5;
    final step = size.width / (n + 1);
    for (var i = 1; i <= n; i++) {
      final p = step * i;
      canvas.drawLine(Offset(p, step), Offset(p, size.height - step), paint);
      canvas.drawLine(Offset(step, p), Offset(size.width - step, p), paint);
    }
    // центральная звёздная точка
    final star = Paint()..color = AppColors.woodLine;
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), 3.5, star);
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
