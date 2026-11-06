import 'package:flutter/material.dart';
import '../theme/theme.dart';

class PodcastsView extends StatelessWidget {
  const PodcastsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.headphones_outlined,
              size: 48,
              color: AppColors.primary500,
            ),
            const SizedBox(height: AppSpacing.md16),
            Text(
              'Podcast',
              style: AppTypography.h5.copyWith(
                color: AppColors.neutral700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm8),
            Text(
              'Aquí irá el contenido de Podcast.',
              textAlign: TextAlign.center,
              style: AppTypography.body2.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
