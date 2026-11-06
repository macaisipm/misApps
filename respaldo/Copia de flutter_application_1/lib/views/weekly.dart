import 'package:flutter/material.dart';
import '../theme/theme.dart';

class WeeklyView extends StatefulWidget {
  const WeeklyView({super.key});

  @override
  State<WeeklyView> createState() => _WeeklyViewState();
}

class _WeeklyViewState extends State<WeeklyView> {
  String _categoriaSeleccionada = 'Today';

  final List<String> _categorias = [
    'The world this week',
    'Leaders',
    'Letters',
    'By Invitation',
    'Essay',
    'United States',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md16),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categorias.map((categoria) {
              final seleccionada =
                  _categoriaSeleccionada == categoria;

              return Padding(
                padding: const EdgeInsets.only(
                  right: AppSpacing.sm8,
                ),
                child: ChoiceChip(
                  label: Text(
                    categoria,
                    style: AppTypography.subtitle2.copyWith(
                      color: seleccionada
                          ? AppColors.neutral100
                          : AppColors.secondary600,
                    ),
                  ),
                  selected: seleccionada,
                  showCheckmark: false,
                  backgroundColor: AppColors.neutral100,
                  selectedColor: AppColors.secondary300,
                  side: BorderSide(
                    color: seleccionada
                        ? AppColors.secondary300
                        : AppColors.secondary100,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (_) {
                    setState(() {
                      _categoriaSeleccionada = categoria;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: AppSpacing.md16),

        // Aquí puedes agregar el contenido de Weekly.
      ],
    );
  }
}