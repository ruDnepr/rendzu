import 'package:flutter/material.dart';
import 'package:rendzu/core/theme/app_theme.dart';

/// Экран «Правила» — наследует оформление «Шашек для Дианы».
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Правила',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: const [
          Intro(
            eyebrow: 'КАК ИГРАТЬ ✦',
            title: 'Пять в ряд',
            subtitle: 'Ставь камни на пересечения линий и собери пять подряд.',
          ),
          SizedBox(height: 18),
          _RuleCard(
            icon: Icons.check_circle_rounded,
            color: purple,
            title: 'Гомоку (просто)',
            lines: [
              'Первым построил пять камней в ряд — победа.',
              'Шесть и больше (оверлайн) тоже считается победой.',
              'Запрещённых ходов нет — отличный режим для начала.',
            ],
          ),
          _RuleCard(
            icon: Icons.warning_rounded,
            color: const Color(0xFFE27D60),
            title: 'Рэндзю (запреты для чёрных)',
            lines: [
              'Чёрные побеждают ТОЛЬКО ровно пятью. Шесть+ — не победа, а запрет.',
              'Белые побеждают пятью и более.',
              'Чёрным нельзя создавать одним ходом:',
              '• двойное три (3-3) — два «три» сразу;',
              '• двойное четыре (4-4) — два «четыре» сразу;',
              '• оверлайн — шесть и больше в ряд.',
              '«Три» — три камня, достроив которые до открытой четвёрки.',
              '«Четыре» — четыре камня, достроив которые до пяти.',
              'Исключение: запрещённый ход, который одновременно строит ровно пять, — победа чёрных.',
            ],
          ),
          _RuleCard(
            icon: Icons.child_care_rounded,
            color: const Color(0xFFF4CB67),
            title: 'Помощь для тебя',
            lines: [
              'Доска 9×9 по умолчанию — быстрее и понятнее.',
              'Включи подсказки: подсветим тройки, четвёрки и хорошие ходы.',
              'Запрещённый ход не дадим сделать — объясним, почему.',
              'Можно отменить последний ход кнопкой «Отменить».',
            ],
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.lines,
  });
  final IconData icon;
  final Color color;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.92),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: ink)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: TextStyle(color: color, fontSize: 15)),
                  Expanded(
                    child: Text(line,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                            color: muted)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
