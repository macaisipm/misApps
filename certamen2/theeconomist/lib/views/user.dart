import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

// temas 
const _temasPrincipales = [
  'Strange but true',
  'News you can see',
  'War in the Middle East',
  'Ukraine at war',
  'Climate change',
  'Geopolitics',
  'Economy',
  'Artificial intelligence',
];

// temas extra "See all topics"
const _temasExtra = [
  'US politics',
  'Business',
  'China',
  'Asia',
  'Europe',
  'Americas',
  'Technology',
  'Science',
];



class BotonGuardar extends StatelessWidget {
  const BotonGuardar({super.key, required this.noticiaId});

  final String noticiaId;

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) return const SizedBox.shrink();

    final ref = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuario.uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snapshot) {
        final guardadas = List<String>.from(
          snapshot.data?.data()?['guardadas'] as List? ?? const [],
        );

        final guardada = guardadas.contains(noticiaId);

        return IconButton(
          tooltip: guardada ? 'Quitar de guardados' : 'Guardar noticia',
          visualDensity: VisualDensity.compact,
          onPressed: () {
            ref.set({
              'guardadas': guardada
                  ? FieldValue.arrayRemove([noticiaId])
                  : FieldValue.arrayUnion([noticiaId]),
            }, SetOptions(merge: true));
          },
          icon: Icon(
            guardada ? Icons.bookmark : Icons.bookmark_border,
            color: guardada ? AppColors.secondary300 : AppColors.neutral600,
          ),
        );
      },
    );
  }
}


class UserView extends StatefulWidget {
  const UserView({super.key, this.onAbrirNoticia});

  // abre el detalle de una noticia 
  final ValueChanged<Map<String, dynamic>>? onAbrirNoticia;

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  final Set<String> _seleccionados = {};

  late final Stream<DocumentSnapshot<Map<String, dynamic>>>? _usuarioStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _articulosStream;

  int _pestana = 0;
  bool _verTodos = false;
  bool _guardando = false;

  DocumentReference<Map<String, dynamic>>? get _refUsuario {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) return null;

    return FirebaseFirestore.instance.collection('usuarios').doc(usuario.uid);
  }

  @override
  void initState() {
    super.initState();

    _usuarioStream = _refUsuario?.snapshots();

    _articulosStream = FirebaseFirestore.instance
        .collection('articulo')
        .orderBy('creadoEn', descending: true)
        .limit(50)
        .snapshots();

    _cargarTemas();
  }

  void _mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            texto,
            style: AppTypography.body2.copyWith(color: AppColors.neutral100),
          ),
        ),
      );
  }

  // cargar los temas que el usuario ya habia elegido
  Future<void> _cargarTemas() async {
    try {
      final doc = await _refUsuario?.get();

      final temas = List<String>.from(
        doc?.data()?['temas'] as List? ?? const [],
      );

      if (mounted) setState(() => _seleccionados.addAll(temas));
    } catch (_) {}
  }

  // guardar los temas elegidos
  Future<void> _comenzar() async {
    final ref = _refUsuario;

    if (ref == null) return;

    setState(() => _guardando = true);

    try {
      await ref.set({
        'temas': _seleccionados.toList(),
      }, SetOptions(merge: true));

      _mensaje('Temas guardados');
    } catch (e) {
      _mensaje('No se pudieron guardar los temas: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // Topics / Bookmarks
  Widget _botonPestana(String texto, int indice) {
    final activa = _pestana == indice;

    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppShapes.radius8),
    );

    if (activa) {
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondary300,
          foregroundColor: AppColors.neutral100,
          shape: forma,
          textStyle: AppTypography.subtitle1,
        ),
        onPressed: () => setState(() => _pestana = indice),
        child: Text(texto),
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondary300,
        side: const BorderSide(color: AppColors.secondary300),
        shape: forma,
        textStyle: AppTypography.body1,
      ),
      onPressed: () => setState(() => _pestana = indice),
      child: Text(texto),
    );
  }

  // chip de un tema
  Widget _chipTema(String tema) {
    final elegido = _seleccionados.contains(tema);

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: elegido ? AppColors.neutral100 : AppColors.neutral600,
        backgroundColor: elegido ? AppColors.secondary300 : null,
        side: BorderSide(
          color: elegido ? AppColors.secondary300 : AppColors.neutral600,
        ),
        shape: const StadiumBorder(),
        textStyle: AppTypography.body1,
        iconSize: AppSpacing.md16,
      ),
      onPressed: () {
        setState(() {
          if (elegido) {
            _seleccionados.remove(tema);
          } else {
            _seleccionados.add(tema);
          }
        });
      },
      icon: const Icon(Icons.add),
      label: Text(tema),
    );
  }

  Widget _temas() {
    final temas = _verTodos
        ? [..._temasPrincipales, ..._temasExtra]
        : _temasPrincipales;

    final puedeComenzar = _seleccionados.isNotEmpty && !_guardando;

    return LayoutBuilder(
      builder: (context, restricciones) => SingleChildScrollView(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: restricciones.maxHeight),
        padding: const EdgeInsets.all(AppSpacing.lg24),
        decoration: BoxDecoration(
          color: AppColors.tertiary100,
          borderRadius: BorderRadius.circular(AppShapes.radius4),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg24),

            Text(
              'Start following topics',
              textAlign: TextAlign.center,
              style: AppTypography.subtitle1.copyWith(
                color: AppColors.neutral800,
              ),
            ),

            const SizedBox(height: AppSpacing.md16),

            Text(
              'Discover more by following topics that interest you',
              textAlign: TextAlign.center,
              style: AppTypography.body1.copyWith(color: AppColors.neutral800),
            ),

            const SizedBox(height: AppSpacing.xxl48),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.md16,
              runSpacing: AppSpacing.sm8,
              children: temas.map(_chipTema).toList(),
            ),

            const SizedBox(height: AppSpacing.xl32),

            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.neutral600,
                textStyle: AppTypography.body1,
              ),
              onPressed: () => setState(() => _verTodos = !_verTodos),
              child: Text(_verTodos ? 'See fewer topics' : 'See all topics'),
            ),

            const SizedBox(height: AppSpacing.md16),

            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.neutral700,
                disabledForegroundColor: AppColors.neutral400,
                textStyle: AppTypography.body1,
              ),
              onPressed: puedeComenzar ? _comenzar : null,
              child: const Text('Get started'),
            ),

            const SizedBox(height: AppSpacing.lg24),
          ],
        ),
      ),
      ),
    );
  }

  // noticias guardadas
  Widget _guardadas() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _usuarioStream,
      builder: (context, usuarioSnap) {
        final ids = List<String>.from(
          usuarioSnap.data?.data()?['guardadas'] as List? ?? const [],
        );

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _articulosStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'No se pudieron cargar las noticias guardadas.',
                style: AppTypography.body2.copyWith(color: AppColors.error500),
              );
            }

            if (!snapshot.hasData || !usuarioSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final documentos = snapshot.data!.docs
                .where((doc) => ids.contains(doc.id))
                .toList();

            if (documentos.isEmpty) {
              return Center(
                child: Text(
                  'Todavía no has guardado noticias.\n'
                  'Toca el ícono de guardar en el Home.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
              );
            }

            return ListView.separated(
              itemCount: documentos.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: AppColors.neutral300),
              itemBuilder: (context, indice) {
                final doc = documentos[indice];
                final noticia = doc.data();

                final imagen = noticia['imagen'] as String? ?? '';
                final titulo = noticia['titulo'] as String? ?? 'Sin título';
                final tema = noticia['categoria'] as String? ?? '';

                return InkWell(
                  onTap: () => widget.onAbrirNoticia?.call(noticia),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppShapes.radius8,
                            ),
                            child: AspectRatio(
                              aspectRatio: 1,
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
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.broken_image_outlined,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(width: AppSpacing.md16),

                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tema,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary500,
                                ),
                              ),
                              Text(
                                titulo,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.h6.copyWith(
                                  color: AppColors.neutral800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        BotonGuardar(noticiaId: doc.id),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _botonPestana('Topics', 0),
              const SizedBox(width: AppSpacing.sm8),
              _botonPestana('Bookmarks', 1),
            ],
          ),

          const SizedBox(height: AppSpacing.lg24),

          Expanded(child: _pestana == 0 ? _temas() : _guardadas()),
        ],
      ),
    );
  }
}