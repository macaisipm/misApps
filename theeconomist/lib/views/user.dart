import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'bookmarks.dart';
import 'podcasts.dart';
import 'video.dart';

export 'bookmarks.dart' show BotonGuardar;

// Temas que se muestran al inicio
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

// Temas extra que aparecen con "See all topics"
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



class UserView extends StatefulWidget {
  const UserView({super.key, this.onAbrirNoticia});

  
  final ValueChanged<Map<String, dynamic>>? onAbrirNoticia;

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  final Set<String> _seleccionados = {};

  late final Stream<DocumentSnapshot<Map<String, dynamic>>>? _usuarioStream;

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

  // Cargar los temas que el usuario ya había elegido
  Future<void> _cargarTemas() async {
    try {
      final doc = await _refUsuario?.get();

      final temas = List<String>.from(
        doc?.data()?['temas'] as List? ?? const [],
      );

      if (mounted) setState(() => _seleccionados.addAll(temas));
    } catch (_) {}
  }

  // Guardar los temas elegidos
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

  // Botones de pestaña: Topics / Bookmarks
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

  // Chip de un tema
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

//bookmarks
  Widget _guardadas() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _usuarioStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('No se pudieron cargar los guardados.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final datos = snapshot.data?.data();
        final secciones = {
          TipoGuardado.noticia: idsGuardados(datos, TipoGuardado.noticia),
          TipoGuardado.podcast: idsGuardados(datos, TipoGuardado.podcast),
          TipoGuardado.video: idsGuardados(datos, TipoGuardado.video),
        }..removeWhere((_, ids) => ids.isEmpty);

        if (secciones.isEmpty) {
          return const Center(
            child: Text(
              'Todavía no tienes guardados.\n'
              'Toca el ícono de marcador para guardar contenido.',
              textAlign: TextAlign.center,
            ),
          );
        }

        final grupos = secciones.entries.toList();
        return ListView(
          children: [
            for (var i = 0; i < grupos.length; i++) ...[
              if (i > 0) ...[
                const SizedBox(height: AppSpacing.md16),
                const Divider(
                  color: AppColors.neutral300,
                  thickness: 2,
                ),
                const SizedBox(height: AppSpacing.md16),
              ],
              ..._seccionGuardada(grupos[i].key, grupos[i].value),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _seccionGuardada(TipoGuardado tipo, List<String> ids) {
    final titulo = switch (tipo) {
      TipoGuardado.noticia => 'Noticias',
      TipoGuardado.podcast => 'Podcasts',
      TipoGuardado.video => 'Videos',
    };

    Widget tarjeta(String id) {
      return _TarjetaGuardada(
        key: ValueKey((tipo, id)),
        tipo: tipo,
        id: id,
        onAbrirNoticia: widget.onAbrirNoticia,
      );
    }

    return [
      Text(
        titulo,
        style: AppTypography.caption.copyWith(color: AppColors.neutral600),
      ),
      const SizedBox(height: AppSpacing.md16),

      for (var i = 0; i < ids.length; i += 2) ...[
        if (i > 0) const SizedBox(height: AppSpacing.lg24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: tarjeta(ids[i])),
            const SizedBox(width: AppSpacing.lg24),
            Expanded(
              child: i + 1 < ids.length
                  ? tarjeta(ids[i + 1])
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    ];
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
class _TarjetaGuardada extends StatefulWidget {
  const _TarjetaGuardada({
    super.key,
    required this.tipo,
    required this.id,
    required this.onAbrirNoticia,
  });

  final TipoGuardado tipo;
  final String id;
  final ValueChanged<Map<String, dynamic>>? onAbrirNoticia;

  @override
  State<_TarjetaGuardada> createState() => _TarjetaGuardadaState();
}

class _TarjetaGuardadaState extends State<_TarjetaGuardada> {
  late final _stream = FirebaseFirestore.instance
      .collection(widget.tipo.coleccion)
      .doc(widget.id)
      .snapshots();

  void _abrir(DocumentSnapshot<Map<String, dynamic>> doc) {
    switch (widget.tipo) {
      case TipoGuardado.noticia:
        widget.onAbrirNoticia?.call({...doc.data()!, 'id': doc.id});
      case TipoGuardado.video:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReproductorShortsScreen(
              videos: [VideoItem.desde(doc)],
              indice: 0,
            ),
          ),
        );
      case TipoGuardado.podcast:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReproductorPodcastScreen(
              episodios: [Episodio.desde(doc)],
              indice: 0,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        final doc = snapshot.data;
        final datos = doc?.data();
        final imagen = datos?['imagen'] as String? ?? '';
        final titulo = snapshot.hasError
            ? 'No se pudo cargar'
            : doc == null
                ? 'Cargando…'
                : datos == null
                    ? 'Contenido no disponible'
                    : datos['titulo'] as String? ?? 'Sin título';

        final descripcion = switch (widget.tipo) {
          TipoGuardado.noticia => datos?['resumen'] as String? ?? '',
          TipoGuardado.video => datos?['categoria'] as String? ?? '',
          TipoGuardado.podcast => datos?['descripcion'] as String? ?? '',
        };

        return InkWell(
          onTap: doc == null || datos == null ? null : () => _abrir(doc),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppShapes.radius8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: imagen.isEmpty
                      ? const ColoredBox(
                          color: AppColors.tertiary200,
                          child: Center(child: Icon(Icons.image_outlined)),
                        )
                      : Image.network(
                          imagen,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: AppColors.tertiary200,
                            child: Center(child: Icon(Icons.broken_image_outlined)),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm8),

              Text(
                titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.h5.copyWith(color: AppColors.neutral800),
              ),
              if (descripcion.isNotEmpty)
                Text(
                  descripcion,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.subtitle1.copyWith(color: AppColors.neutral600),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: BotonGuardar(noticiaId: widget.id, tipo: widget.tipo),
              ),
            ],
          ),
        );
      },
    );
  }
}
