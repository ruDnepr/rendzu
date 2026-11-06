import 'package:flutter/material.dart';
import 'package:rendzu/core/theme/app_theme.dart';

/// Экран «Правила»: общие принципы, гомоку, рэндзю (с запрещёнными ходами),
/// упрощения для ребёнка.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Правила')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _RuleCard(
              icon: Icons.info,
              color: AppColors.sky,
              title: 'Как играть',
              body: [
                'Двое игроков ставят камни по очереди на пересечения линий.',
                'Чёрные ходят первыми.',
                'Цель — первым построить ряд из пяти своих камней по '
                    'горизонтали, вертикали или диагонали.',
              ],
            ),
            _RuleCard(
              icon: Icons.check_circle,
              color: AppColors.grass,
              title: 'Гомоку (простые правила)',
              body: [
                'Побеждает тот, кто первым построит пять камней в ряд '
                    '(или больше — оверлайн тоже считается победой).',
                'Запрещённых ходов нет ни у кого.',
                'Это режим по умолчанию — отлично подходит для начала!',
              ],
            ),
            _RuleCard(
              icon: Icons.warning,
              color: AppColors.coral,
              title: 'Рэндзю (для чёрных есть запреты)',
              body: [
                'Чёрные побеждают ТОЛЬКО ровно пятью камнями. Шесть и больше '
                    '(оверлайн) — НЕ победа для чёрных, а запрещённый ход.',
                'Белые побешдают пятью и более камнями.',
                'Запрещено чёрным создавать одновременно:',
                '• Двойное три (3-3) — два «три» одним ходом.',
                '• Двойное четыре (4-4) — два «четыре» одним ходом.',
                '• Оверлайн — шесть и больше в ряд.',
                '«Три» — три камня, к которым можно добавить один и получить '
                    'открытую четвёрку (с двух сторон).',
                '«Четыре» — четыре камня, к которым можно добавить один и '
                    'получить пять.',
                'Исключение: если чёрные делают запрещённый ход И одновременно '
                    'строят ровно пять — это победа чёрных!',
              ],
            ),
            _RuleCard(
              icon: Icons.child_care,
              color: AppColors.sunflower,
              title: 'Помощь для тебя',
              body: [
                'Доска 9×9 по умолчанию — быстрее и понятнее.',
                'Включи подсказки: приложение подсветит тройки и четвёрки, '
                    'покажет хорошие ходы.',
                'Если ты играешь чёрными в рэндзю и пробуешь сделать '
                    'запрещённый ход — приложение не даст его сделать и '
                    'объяснит почему. Ты не проиграешь случайно!',
                'Можно отменить последний ход (кнопка «Отменить»).',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color color;
  final String title;
  final List<String> body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...body.map((line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ', style: TextStyle(color: color, fontSize: 16)),
                      Expanded(
                        child: Text(line,
                            style: Theme.of(context).textTheme.bodyLarge),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
