import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../theme/theme.dart';

// selector de videos
const _tipos = ['Shorts', 'Insider'];

// proporciones de las tarjetas
const double _proporcionDestacado = 0.65;
const double _proporcionLista = 1.85;

class VideoItem {
  const VideoItem({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.tipo,
    required this.url,
    required this.imagen,
    required this.duracion,
  });

  final String id;
  final String titulo;
  final String categoria;
  final String tipo;
  final String url;
  final String imagen;
  final String duracion;

  factory VideoItem.desde(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final datos = doc.data();

    return VideoItem(
      id: doc.id,
      titulo: datos['titulo'] as String? ?? 'Sin título',
      categoria: datos['categoria'] as String? ?? '',
      tipo: datos['tipo'] as String? ?? _tipos.first,
      url: datos['url'] as String? ?? '',
      imagen: datos['imagen'] as String? ?? '',
      duracion: datos['duracion'] as String? ?? '',
    );
  }
}

// pantalla de videos
class VideoView extends StatefulWidget {
  const VideoView({super.key});

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  final _videos = FirebaseFirestore.instance.collection('video');
  final _picker = ImagePicker();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  String _tipoActual = _tipos.first;

  @override
  void initState() {
    super.initState();
    _stream = _videos.orderBy('creadoEn', descending: true).snapshots();
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

  void _abrir(List<VideoItem> lista, int indice) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReproductorShortsScreen(videos: lista, indice: indice),
      ),
    );
  }

  // menu al mantener presionada una tarjeta
  void _opciones(VideoItem video) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.neutral100,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text('Editar', style: AppTypography.body1),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _formulario(video: video);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text('Eliminar', style: AppTypography.body1),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _eliminar(video);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminar(VideoItem video) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Eliminar video', style: AppTypography.h6),
        content: Text(
          '¿Quieres eliminar "${video.titulo}"?',
          style: AppTypography.body1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _videos.doc(video.id).delete();

      if (video.imagen.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(video.imagen).delete();
        } catch (_) {}
      }

      _mensaje('Video eliminado');
    } catch (e) {
      _mensaje('No se pudo eliminar el video: $e');
    }
  }

  // agregar un video nuevo o editar uno existente
  Future<void> _formulario({VideoItem? video}) async {
    final formKey = GlobalKey<FormState>();

    final tituloController = TextEditingController(text: video?.titulo);
    final categoriaController = TextEditingController(text: video?.categoria);
    final urlController = TextEditingController(text: video?.url);
    final duracionController = TextEditingController(text: video?.duracion);

    XFile? imagen;
    bool guardando = false;
    String tipo = video?.tipo ?? _tipoActual;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: AppColors.neutral100,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              Future<void> seleccionarImagen() async {
                try {
                  final seleccion = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                    maxWidth: 1600,
                  );

                  if (seleccion != null && sheetContext.mounted) {
                    setSheetState(() => imagen = seleccion);
                  }
                } catch (e) {
                  _mensaje('No se pudo seleccionar la imagen: $e');
                }
              }

              Future<void> guardar() async {
                if (guardando || !formKey.currentState!.validate()) return;

                if (video == null && imagen == null) {
                  _mensaje('Selecciona una imagen para el video.');
                  return;
                }

                setSheetState(() => guardando = true);

                Reference? referencia;

                try {
                  final docId = video?.id ?? _videos.doc().id;
                  String urlImagen = video?.imagen ?? '';
                  if (imagen != null) {
                    final extension = imagen!.name
                        .split('.')
                        .last
                        .toLowerCase();

                    final contentType = extension == 'png'
                        ? 'image/png'
                        : extension == 'webp'
                        ? 'image/webp'
                        : 'image/jpeg';

                    final sufijo =
                        ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
                        ? extension
                        : 'jpg';

                    referencia = FirebaseStorage.instance.ref(
                      'imagenes/video_$docId.$sufijo',
                    );

                    await referencia.putFile(
                      File(imagen!.path),
                      SettableMetadata(contentType: contentType),
                    );

                    urlImagen = await referencia.getDownloadURL();
                  }

                  final contenido = <String, dynamic>{
                    'titulo': tituloController.text.trim(),
                    'categoria': categoriaController.text.trim(),
                    'tipo': tipo,
                    'url': urlController.text.trim(),
                    'duracion': duracionController.text.trim(),
                    'imagen': urlImagen,
                  };

                  if (video == null) {
                    await _videos.doc(docId).set({
                      ...contenido,
                      'creadoEn': FieldValue.serverTimestamp(),
                    });
                  } else {
                    await _videos.doc(docId).update(contenido);
                  }

                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                } catch (e) {
                  if (referencia != null) {
                    try {
                      await referencia.delete();
                    } catch (_) {}
                  }

                  _mensaje('No se pudo guardar el video: $e');

                  if (sheetContext.mounted) {
                    setSheetState(() => guardando = false);
                  }
                }
              }

              return PopScope(
                canPop: !guardando,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md16,
                    AppSpacing.sm8,
                    AppSpacing.md16,
                    MediaQuery.viewInsetsOf(sheetContext).bottom +
                        AppSpacing.lg24,
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video == null ? 'Nuevo video' : 'Editar video',
                            style: AppTypography.h6.copyWith(
                              color: AppColors.primary500,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md16),

                          TextFormField(
                            controller: tituloController,
                            enabled: !guardando,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Título',
                            ),
                            validator: (valor) =>
                                valor == null || valor.trim().isEmpty
                                ? 'Ingresa un título'
                                : null,
                          ),

                          const SizedBox(height: AppSpacing.md16),

                          TextFormField(
                            controller: categoriaController,
                            enabled: !guardando,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Categoría (ej. Britain)',
                            ),
                            validator: (valor) =>
                                valor == null || valor.trim().isEmpty
                                ? 'Ingresa una categoría'
                                : null,
                          ),

                          const SizedBox(height: AppSpacing.md16),

                          DropdownButtonFormField<String>(
                            initialValue: tipo,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Tipo',
                            ),
                            items: _tipos
                                .map(
                                  (valor) => DropdownMenuItem<String>(
                                    value: valor,
                                    child: Text(
                                      valor,
                                      style: AppTypography.body1,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: guardando
                                ? null
                                : (valor) {
                                    if (valor != null) {
                                      setSheetState(() => tipo = valor);
                                    }
                                  },
                          ),

                          const SizedBox(height: AppSpacing.md16),

                          TextFormField(
                            controller: urlController,
                            enabled: !guardando,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(
                              labelText: 'URL del video (mp4)',
                            ),
                            validator: (valor) =>
                                (valor ?? '').trim().startsWith('http')
                                ? null
                                : 'Ingresa un enlace que parta con http',
                          ),

                          const SizedBox(height: AppSpacing.md16),

                          TextFormField(
                            controller: duracionController,
                            enabled: !guardando,
                            keyboardType: TextInputType.datetime,
                            decoration: const InputDecoration(
                              labelText: 'Duración (ej. 5:23)',
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md16),

                          // vista previa de la imagen
                          if (imagen != null ||
                              (video?.imagen ?? '').isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppShapes.radius8,
                              ),
                              child: AspectRatio(
                                aspectRatio: _proporcionLista,
                                child: Image(
                                  image: imagen != null
                                      ? FileImage(File(imagen!.path))
                                      : NetworkImage(video!.imagen)
                                            as ImageProvider,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm8),
                          ],

                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              textStyle: AppTypography.button,
                              foregroundColor: AppColors.secondary300,
                              side: const BorderSide(
                                color: AppColors.secondary300,
                              ),
                            ),
                            onPressed: guardando ? null : seleccionarImagen,
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                            ),
                            label: Text(
                              imagen == null && (video?.imagen ?? '').isEmpty
                                  ? 'Seleccionar imagen'
                                  : 'Cambiar imagen',
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg24),

                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                textStyle: AppTypography.button,
                              ),
                              onPressed: guardando ? null : guardar,
                              icon: const Icon(Icons.check),
                              label: Text(
                                guardando ? 'Guardando…' : 'Guardar video',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 350));

      tituloController.dispose();
      categoriaController.dispose();
      urlController.dispose();
      duracionController.dispose();
    }
  }

  // Shorts / Insider
  Widget _segmento(String tipo) {
    final activo = _tipoActual == tipo;

    return GestureDetector(
      onTap: () => setState(() => _tipoActual = tipo),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md16,
          vertical: AppSpacing.sm8,
        ),
        decoration: BoxDecoration(
          color: activo ? AppColors.secondary300 : null,
          borderRadius: BorderRadius.circular(AppShapes.radius24),
        ),
        child: Text(
          tipo,
          style: (activo ? AppTypography.subtitle1 : AppTypography.body1)
              .copyWith(
                color: activo ? AppColors.neutral100 : AppColors.secondary300,
              ),
        ),
      ),
    );
  }

  Widget _selector() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs4),
        decoration: BoxDecoration(
          color: AppColors.tertiary100,
          borderRadius: BorderRadius.circular(AppShapes.radius24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _tipos.map(_segmento).toList(),
        ),
      ),
    );
  }

  // tarjeta 
  Widget _tarjeta(
    VideoItem video, {
    required bool destacado,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _opciones(video),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppShapes.radius4),
        child: AspectRatio(
          aspectRatio: destacado ? _proporcionDestacado : _proporcionLista,
          child: Stack(
            fit: StackFit.expand,
            children: [
              video.imagen.isEmpty
                  ? const ColoredBox(color: AppColors.tertiary200)
                  : Image.network(
                      video.imagen,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: AppColors.tertiary200),
                    ),

              // degradado oscuro en la parte de abajo
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.neutral800],
                    stops: [0.55, 1],
                  ),
                ),
              ),

              Positioned(
                left: AppSpacing.md16,
                right: AppSpacing.md16,
                bottom: AppSpacing.md16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.categoria.toUpperCase(),
                      style: AppTypography.subtitle2.copyWith(
                        color: AppColors.neutral100,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm8),

                    Text(
                      video.titulo,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (destacado ? AppTypography.h5 : AppTypography.h6)
                              .copyWith(
                                color: AppColors.neutral100,
                                fontWeight: FontWeight.w600,
                              ),
                    ),

                    const SizedBox(height: AppSpacing.sm8),

                    Row(
                      children: [
                        const Icon(
                          Icons.play_arrow_outlined,
                          color: AppColors.neutral100,
                          size: AppSpacing.xl32,
                        ),
                        const SizedBox(width: AppGap.normal8),
                        Text(
                          video.duracion,
                          style: AppTypography.body2.copyWith(
                            color: AppColors.neutral100,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral100,

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.neutral100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShapes.radius24),
        ),
        tooltip: 'Agregar video',
        onPressed: () => _formulario(),
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'No se pudieron cargar los videos.',
                style: AppTypography.body2.copyWith(color: AppColors.error500),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final videos = snapshot.data!.docs
              .map(VideoItem.desde)
              .where((video) => video.tipo == _tipoActual)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md16,
              AppSpacing.md16,
              AppSpacing.md16,
              AppSpacing.xxl48 + AppSpacing.xl32,
            ),
            children: [
              _selector(),

              const SizedBox(height: AppSpacing.lg24),

              if (videos.isEmpty)
                Text(
                  'Todavía no hay videos en esta sección. '
                  'Agrega uno con el botón +',
                  textAlign: TextAlign.center,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),

              if (videos.isNotEmpty)
                _tarjeta(
                  videos.first,
                  destacado: true,
                  onTap: () => _abrir(videos, 0),
                ),

              if (videos.length > 1) ...[
                const SizedBox(height: AppSpacing.md16),

                const Divider(color: AppColors.neutral300),

                const SizedBox(height: AppSpacing.md16),

                Text(
                  'Latest',
                  style: AppTypography.subtitle1.copyWith(
                    color: AppColors.neutral800,
                  ),
                ),

                const SizedBox(height: AppSpacing.md16),

                for (var i = 1; i < videos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md16),
                    child: _tarjeta(
                      videos[i],
                      destacado: false,
                      onTap: () => _abrir(videos, i),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// reproductor estilo reels
class ReproductorShortsScreen extends StatefulWidget {
  const ReproductorShortsScreen({
    super.key,
    required this.videos,
    required this.indice,
  });

  final List<VideoItem> videos;
  final int indice;

  @override
  State<ReproductorShortsScreen> createState() =>
      _ReproductorShortsScreenState();
}

class _ReproductorShortsScreenState extends State<ReproductorShortsScreen> {
  late final PageController _paginas;
  late int _actual;

  @override
  void initState() {
    super.initState();
    _actual = widget.indice;
    _paginas = PageController(initialPage: widget.indice);
  }

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral800,
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _paginas,
            itemCount: widget.videos.length,
            onPageChanged: (indice) => setState(() => _actual = indice),
            itemBuilder: (context, indice) => _PaginaShort(
              video: widget.videos[indice],
              activo: indice == _actual,
            ),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                tooltip: 'Volver',
                color: AppColors.neutral100,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// pagina del short
class _PaginaShort extends StatefulWidget {
  const _PaginaShort({required this.video, required this.activo});

  final VideoItem video;
  final bool activo;

  @override
  State<_PaginaShort> createState() => _PaginaShortState();
}

class _PaginaShortState extends State<_PaginaShort> {
  VideoPlayerController? _controller;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    if (widget.activo) _iniciar();
  }

  @override
  void didUpdateWidget(covariant _PaginaShort anterior) {
    super.didUpdateWidget(anterior);

    if (widget.activo && !anterior.activo) {
      final controller = _controller;

      if (controller == null) {
        _iniciar();
      } else {
        controller.seekTo(Duration.zero);
        controller.play();
      }
    } else if (!widget.activo && anterior.activo) {
      _controller?.pause();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _iniciar() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.url),
    );

    _controller = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);

      if (!mounted) return;
      setState(() {});

      if (widget.activo) controller.play();
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _alternar() {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  // indicador de carga 
  Widget _cargando() {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.video.imagen.isEmpty
            ? const ColoredBox(color: AppColors.neutral800)
            : Image.network(
                widget.video.imagen,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: AppColors.neutral800),
              ),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  // video
  Widget _video(VideoPlayerController controller) {
    final tamano = controller.value.size;

    if (controller.value.aspectRatio < 1) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: tamano.width,
            height: tamano.height,
            child: VideoPlayer(controller),
          ),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: VideoPlayer(controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final video = widget.video;

    final listo = controller != null && controller.value.isInitialized;

    return GestureDetector(
      onTap: _alternar,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_error)
            Center(
              child: Text(
                'No se pudo reproducir el video.',
                style: AppTypography.body2.copyWith(
                  color: AppColors.neutral100,
                ),
              ),
            )
          else if (!listo)
            _cargando()
          else
            _video(controller),

          // Degradado oscuro para que se lea el texto
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.neutral800],
                stops: [0.6, 1],
              ),
            ),
          ),

          // icono de play 
          if (listo)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, valor, _) {
                if (valor.isPlaying) return const SizedBox.shrink();

                return const Center(
                  child: Icon(
                    Icons.play_arrow,
                    size: AppSpacing.xxl48,
                    color: AppColors.neutral100,
                  ),
                );
              },
            ),

          Positioned(
            left: AppSpacing.md16,
            right: AppSpacing.md16,
            bottom: AppSpacing.lg24,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.categoria.toUpperCase(),
                    style: AppTypography.subtitle2.copyWith(
                      color: AppColors.neutral100,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm8),

                  Text(
                    video.titulo,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h5.copyWith(
                      color: AppColors.neutral100,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // barra de progreso 
          if (listo)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: AppColors.secondary300,
                  bufferedColor: AppColors.neutral400,
                  backgroundColor: AppColors.neutral600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}