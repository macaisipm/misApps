import 'package:flutter/material.dart';
import '../theme/theme.dart';

class FlashView extends StatelessWidget {
  const FlashView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      // app bar
      appBar: AppBar(
        title: const Text('Flash'),
      ),

      // contenido
      body: Padding(
        padding: const EdgeInsets.all(
          AppSpacing.md16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // título
            Text(
              'Semana I en UDD',
              style: text.headlineMedium,
            ),

            const SizedBox(
              height: AppSpacing.md16,
            ),

            // noticia
            Text(
              'Esta semana comienza la semana I. Solo tendrán clases los estudiantes de 4 año, se les agradece la paciencia.',
              style: text.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
