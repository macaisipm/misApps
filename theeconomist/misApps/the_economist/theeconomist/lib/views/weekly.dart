import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/theme.dart';

class WeeklyView extends StatefulWidget {
  const WeeklyView({
    super.key,
    required this.onAbrirNoticia,
  });

  final void Function(Map<String, dynamic>) onAbrirNoticia;

  @override
  State<WeeklyView> createState() => _WeeklyViewState();
}

//categorias chips
class _WeeklyViewState extends State<WeeklyView> {
  String _categoriaSeleccionada = 'The world this week';

  final List<String> _categorias = [
    'The world this week',
    'Leaders',
    'Letters',
    'By Invitation',
    'Essay',
    'United States',
  ];

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _noticiasStream;

  @override
  void initState() {
    super.initState();

    _noticiasStream = FirebaseFirestore.instance
        .collection('articulo')
        .orderBy('creadoEn', descending: true)
        .limit(50)
        .snapshots();
  }

  String _fecha(Timestamp? fecha) {
    if (fecha == null) return 'Fecha pendiente';

    final valor = fecha.toDate().toLocal();

    String dos(int numero) => numero.toString().padLeft(2, '0');

    return '${dos(valor.day)}/${dos(valor.month)}/${valor.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md16),
      children: [
        // chips
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

        const SizedBox(height: AppGap.wide24),

        // imagen principal
        ClipRRect(
          borderRadius: BorderRadius.circular(AppShapes.radius4),
          child: Image.asset(
            'assets/img/weekly_img.png',
            width: double.infinity,
            height: 600,
            fit: BoxFit.cover,
          ),
        ),

        const SizedBox(height: AppGap.wide24),

        const Divider(
          color: AppColors.neutral300,
          thickness: 2,
          height: 1,
        ),

        const SizedBox(height: AppGap.wide24),

        // nombre de la seccion
        Text(
          _categoriaSeleccionada,
          style: AppTypography.caption.copyWith(
            color: AppColors.neutral800,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: AppGap.wide24),

        // noticias desde firebase
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _noticiasStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'No se pudieron cargar las noticias.',
                style: AppTypography.body2.copyWith(
                  color: AppColors.error500,
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final documentos = snapshot.data!.docs;

            if (documentos.isEmpty) {
              return Text(
                'Todavía no hay noticias publicadas.',
                style: AppTypography.body2.copyWith(
                  color: AppColors.neutral600,
                ),
              );
            }

            return Column(
              children: documentos.map((doc) {
                final noticia = doc.data();

                final imagen = noticia['imagen'] as String? ?? '';
                final titulo =
                    noticia['titulo'] as String? ?? 'Sin título';
                final resumen = noticia['resumen'] as String? ?? '';
                final tema = noticia['categoria'] as String? ?? '';

                return Card(
                  color: AppColors.neutral100,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => widget.onAbrirNoticia(noticia),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // imagen de la noticia
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AspectRatio(
                              aspectRatio: 1.85,
                              child: imagen.isEmpty
                                  ? const ColoredBox(
                                      color: AppColors.tertiary200,
                                      child: Icon(
                                        Icons.image_outlined,
                                        color: AppColors.neutral600,
                                      ),
                                    )
                                  : Image.network(
                                      imagen,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          const Icon(
                                        Icons.broken_image_outlined,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: AppGap.spacious16),

                          // tema
                          Text(
                            tema,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary500,
                              height: 1.2,
                            ),
                          ),

                          // titulo
                          Text(
                            titulo,
                            style: AppTypography.h5.copyWith(
                              color: AppColors.neutral800,
                            ),
                          ),

                          const SizedBox(height: AppGap.spacious16),

                          // resumen
                          Text(
                            resumen,
                            style: AppTypography.subtitle2.copyWith(
                              color: AppColors.neutral600,
                            ),
                          ),

                          const SizedBox(height: AppGap.wide24),

                          // fecha con iconos
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 24,
                                color: AppColors.neutral800,
                              ),

                              const SizedBox(width: AppGap.normal8),

                              Expanded(
                                child: Text(
                                  _fecha(
                                    noticia['creadoEn'] as Timestamp?,
                                  ),
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.neutral800,
                                  ),
                                ),
                              ),

                              SvgPicture.asset(
                                'assets/iconos/video.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.neutral600,
                                  BlendMode.srcIn,
                                ),
                              ),

                              const SizedBox(width: AppGap.normal8),

                              const Icon(
                                Icons.bookmark_border,
                                size: 24,
                                color: AppColors.neutral600,
                              ),
                            ],
                          ),

                          // divider
                          const Padding(
                            padding: EdgeInsets.only(
                              top: AppMargin.relaxed24,
                            ),
                            child: Divider(
                              color: AppColors.neutral300,
                              thickness: 1,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}