import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rendzu/core/theme/app_theme.dart';

/// Заставка: логотип с камнями, название, через 1.6с — переход в меню.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/menu');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: AppBackground(
          child: Center(
            child: FadeTransition(
              opacity: _anim,
              child: ScaleTransition(
                scale: Tween(begin: .75, end: 1.0).animate(
                  CurvedAnimation(
                      parent: _anim, curve: Curves.elasticOut),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const StoneLogo(size: 130),
                    const SizedBox(height: 30),
                    const Text(
                      'Рэндзю\nдля Дианы',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 37,
                        height: 1.04,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Пять камней в ряд — и победа!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation(purple.withOpacity(.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
