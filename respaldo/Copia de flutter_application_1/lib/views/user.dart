import 'package:flutter/material.dart';
import '../theme/theme.dart';


class UserView extends StatelessWidget {
  const UserView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_outline,
              size: 48,
              color: AppColors.primary500,
            ),
            const SizedBox(height: AppSpacing.md16),
            Text(
              'User',
              style: AppTypography.h5.copyWith(
                color: AppColors.neutral700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm8),
            Text(
              'Aquí irá el contenido de User.',
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
