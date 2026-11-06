import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Палитра «Дианы» — унаследована от «Шашек для Дианы».
//  Фиолетово-кремовая, тёплая, детская.
// ═══════════════════════════════════════════════════════════════════════════
const ink = Color(0xFF3D3154);
const muted = Color(0xFF8B8298);
const purple = Color(0xFF8266D5);
const deepPurple = Color(0xFF6047AF);
const cream = Color(0xFFFFF8ED);
const yellow = Color(0xFFFFD66D);
const peach = Color(0xFFFFD9C7);
const lilac = Color(0xFFEDE6FF);
const coralPeach = Color(0xFFFCE4D7);

// Цвета камней и доски (рендзю)
const stoneBlack = Color(0xFF2A2733);
const stoneBlackHi = Color(0xFF6A6677);
const stoneWhite = Color(0xFFFBFBF6);
const stoneWhiteEdge = Color(0xFFCEB998);
const boardWoodDark = Color(0xFF8C5831);
const boardWoodLight = Color(0xFFB07A45);

ThemeData dianaTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: purple,
      brightness: Brightness.light,
    ),
    fontFamily: 'Nunito',
    scaffoldBackgroundColor: cream,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ink,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 19,
        fontWeight: FontWeight.w900,
        color: ink,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: purple,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 54),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xFFFFFCF6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  Фон приложения — кремово-персиковый градиент с мягкими «свечениями».
// ═══════════════════════════════════════════════════════════════════════════
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFBF4), Color(0xFFFFF3E5), Color(0xFFF5EDFF)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -75,
              right: -90,
              child: _Glow(size: 230, color: yellow.withOpacity(.20)),
            ),
            Positioned(
              top: 310,
              left: -110,
              child: _Glow(size: 200, color: peach.withOpacity(.25)),
            ),
            Positioned(
              bottom: -90,
              right: -50,
              child: _Glow(size: 240, color: purple.withOpacity(.08)),
            ),
            child,
          ],
        ),
      );
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  Каркас страницы: AppBar + AppBackground + центрированный контент (max 520).
// ═══════════════════════════════════════════════════════════════════════════
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.transparentAppBar = false,
  });
  final String title;
  final Widget child;
  final Widget? trailing;
  final bool transparentAppBar;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: transparentAppBar
            ? null
            : AppBar(
                title: Text(title),
                actions:
                    trailing == null ? null : [trailing!, const SizedBox(width: 12)],
              ),
        body: AppBackground(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: child,
              ),
            ),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  Маленькая метка-таблетка (eyebrow).
// ═══════════════════════════════════════════════════════════════════════════
class Eyebrow extends StatelessWidget {
  const Eyebrow(
    this.label, {
    super.key,
    this.color = purple,
    this.background = lilac,
    this.fontSize = 11,
  });
  final String label;
  final Color color;
  final Color background;
  final double fontSize;
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: fontSize < 10 ? 9 : 12,
          vertical: fontSize < 10 ? 4 : 7,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  Заголовок-ввод страницы.
// ═══════════════════════════════════════════════════════════════════════════
class Intro extends StatelessWidget {
  const Intro({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
  });
  final String title;
  final String subtitle;
  final String? eyebrow;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[Eyebrow(eyebrow!), const SizedBox(height: 15)],
          Text(
            title,
            style: const TextStyle(
              fontSize: 29,
              height: 1.12,
              fontWeight: FontWeight.w900,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            subtitle,
            style: const TextStyle(
              color: muted,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  Большая кнопка (как в шашках).
// ═══════════════════════════════════════════════════════════════════════════
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onPressed,
    this.subtitle,
    this.color = purple,
    this.foreground = Colors.white,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color foreground;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(.25),
                offset: const Offset(0, 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: color,
            borderRadius: BorderRadius.circular(21),
            child: InkWell(
              borderRadius: BorderRadius.circular(21),
              onTap: onPressed,
              child: Container(
                constraints: const BoxConstraints(minHeight: 68),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: foreground.withOpacity(.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: foreground, size: 25),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: TextStyle(
                                color: foreground.withOpacity(.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded,
                        color: foreground, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  Карточка-выбор (как в шашках).
// ═══════════════════════════════════════════════════════════════════════════
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.tag,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tag;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF2EAE3)),
          boxShadow: [
            BoxShadow(
              color: ink.withOpacity(.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child:
                        Icon(icon, color: ink.withOpacity(.8), size: 29),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tag != null) ...[
                    const SizedBox(width: 7),
                    Text(
                      tag!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: purple,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFC7BDCA)),
                ],
              ),
            ),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  Маленькая кнопка-плитка (Правила / Настройки).
// ═══════════════════════════════════════════════════════════════════════════
class SmallMenu extends StatelessWidget {
  const SmallMenu({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withOpacity(.82),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: ink, size: 21),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, color: ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  Камень рэндзю — объёмная сфера с бликом (для логотипа/иконок).
// ═══════════════════════════════════════════════════════════════════════════
class StoneIcon extends StatelessWidget {
  const StoneIcon({
    super.key,
    this.dark = true,
    this.size = 48,
  });
  final bool dark;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.35),
            radius: 0.85,
            colors: dark
                ? const [stoneBlackHi, stoneBlack]
                : const [Colors.white, stoneWhite, stoneWhiteEdge],
            stops: dark ? const [0.0, 1.0] : const [0.0, 0.7, 1.0],
          ),
          border: Border.all(
            color: dark ? const Color(0xFF1E1B26) : stoneWhiteEdge,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ink.withOpacity(.22),
              blurRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: size * .30,
            height: size * .30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(dark ? .55 : .9),
            ),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  Логотип «Рэндзю для Дианы» — два камня на маленькой доске.
// ═══════════════════════════════════════════════════════════════════════════
class StoneLogo extends StatelessWidget {
  const StoneLogo({super.key, this.size = 120});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size + 50,
        height: size + 30,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 20,
              top: 12,
              child: Transform.rotate(
                angle: -.12,
                child: Container(
                  width: size,
                  height: size,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: boardWoodDark,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0xFFA66C3D), offset: Offset(0, 7)),
                      BoxShadow(
                        color: Color(0x33714850),
                        blurRadius: 20,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _MiniBoardPainter(),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -6,
              top: -8,
              child: StoneIcon(dark: true, size: size * 0.42),
            ),
            Positioned(
              right: 14,
              bottom: -4,
              child: StoneIcon(dark: false, size: size * 0.34),
            ),
          ],
        ),
      );
}

class _MiniBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF0D9A8)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const n = 5;
    final step = size.width / (n + 1);
    for (var i = 1; i <= n; i++) {
      final p = step * i;
      canvas.drawLine(
          Offset(p, step), Offset(p, size.height - step), paint);
      canvas.drawLine(
          Offset(step, p), Offset(size.width - step, p), paint);
    }
    final star = Paint()..color = const Color(0xFFF0D9A8);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), 2.5, star);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
//  Диалоги — большие кнопки друг под другом.
// ═══════════════════════════════════════════════════════════════════════════
const dialogTextStyle = TextStyle(
  color: muted,
  fontSize: 14,
  fontWeight: FontWeight.w700,
  height: 1.4,
);

class DianaDialogButton<T> {
  const DianaDialogButton({
    required this.label,
    required this.value,
    this.primary = false,
    this.key,
  });
  final String label;
  final T value;
  final bool primary;
  final Key? key;
}

Future<T?> showDianaDialog<T>({
  required BuildContext context,
  required String title,
  required List<DianaDialogButton<T>> actions,
  Widget? content,
  bool barrierDismissible = true,
}) =>
    showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        contentPadding: const EdgeInsets.fromLTRB(22, 6, 22, 20),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 6),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: ink,
            height: 1.15,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (content != null) ...[
              content,
              const SizedBox(height: 16),
            ],
            for (final (index, action) in actions.indexed) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: action.primary
                    ? FilledButton(
                        key: action.key,
                        onPressed: () =>
                            Navigator.pop(dialogContext, action.value),
                        child: Text(action.label),
                      )
                    : OutlinedButton(
                        key: action.key,
                        onPressed: () =>
                            Navigator.pop(dialogContext, action.value),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ink,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE3D8F5)),
                          minimumSize: const Size.fromHeight(56),
                          textStyle: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(action.label),
                      ),
              ),
              if (index != actions.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );

// ═══════════════════════════════════════════════════════════════════════════
//  Конфетти-празднование в диалоге победы.
// ═══════════════════════════════════════════════════════════════════════════
class Celebration extends StatefulWidget {
  const Celebration({super.key, this.calm = false});
  final bool calm;
  @override
  State<Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<Celebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.calm) {
      return Icon(Icons.handshake_rounded, size: 56, color: muted.withOpacity(.5));
    }
    return ScaleTransition(
      scale: Tween(begin: .85, end: 1.1).animate(
        CurvedAnimation(parent: _c, curve: Curves.elasticOut),
      ),
      child: const Icon(Icons.celebration_rounded, size: 56, color: yellow),
    );
  }
}
