import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';

import '../theme/theme.dart';

// secciones
const _secciones = ['Daily and weekly', 'Special series'];

// ancho de cada tarjeta 
const double _anchoTarjeta = 0.45;

class Episodio {
  const Episodio({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.audio,
    required this.imagen,
    required this.seccion,
  });

  final String id;
  final String titulo;
  final String descripcion;
  final String audio;
  final String imagen;
  final String seccion;

  factory Episodio.desde(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final datos = doc.data();

    return Episodio(
      id: doc.id,
      titulo: datos['titulo'] as String? ?? 'Sin título',
      descripcion: datos['descripcion'] as String? ?? '',
      audio: datos['audio'] as String? ?? '',
      imagen: datos['imagen'] as String? ?? '',
      seccion: datos['seccion'] as String? ?? _secciones.first,
    );
  }
}

String _formato(Duration d) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(d.inMinutes)}:${dos(d.inSeconds.remainder(60))}';
}

// portada 
Widget _portada({String url = '', XFile? archivo, double proporcion = 1}) {
  final ImageProvider? imagen = archivo != null
      ? FileImage(File(archivo.path))
      : (url.isEmpty ? null : NetworkImage(url));

  return ClipRRect(
    borderRadius: BorderRadius.circular(AppShapes.radius8),
    child: AspectRatio(
      aspectRatio: proporcion,
      child: imagen == null
          ? const ColoredBox(
              color: AppColors.tertiary200,
              child: Center(
                child: Icon(
                  Icons.headphones_outlined,
                  color: AppColors.neutral600,
                ),
              ),
            )
          : Image(
              image: imagen,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, _, _) =>
                  const Center(child: Icon(Icons.broken_image_outlined)),
            ),
    ),
  );
}


// lista de podcasts
class PodcastsView extends StatefulWidget {
  const PodcastsView({super.key});

  @override
  State<PodcastsView> createState() => _PodcastsViewState();
}

class _PodcastsViewState extends State<PodcastsView> {
  final _episodios = FirebaseFirestore.instance.collection('podcast');
  final _picker = ImagePicker();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _episodios.orderBy('creadoEn', descending: true).snapshots();
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

  void _abrirReproductor(List<Episodio> lista, int indice) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ReproductorPodcastScreen(episodios: lista, indice: indice),
      ),
    );
  }

  // menu al mantener presionada una tarjeta
  void _opciones(Episodio episodio) {
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
                _formulario(episodio: episodio);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text('Eliminar', style: AppTypography.body1),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _eliminar(episodio);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminar(Episodio episodio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Eliminar podcast', style: AppTypography.h6),
        content: Text(
          '¿Quieres eliminar "${episodio.titulo}"?',
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
      await _episodios.doc(episodio.id).delete();

      if (episodio.imagen.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(episodio.imagen).delete();
        } catch (_) {}
      }

      _mensaje('Podcast eliminado');
    } catch (e) {
      _mensaje('No se pudo eliminar el podcast: $e');
    }
  }

  // agregar un podcast nuevo o editar uno existente
  Future<void> _formulario({Episodio? episodio}) async {
    final formKey = GlobalKey<FormState>();

    final tituloController = TextEditingController(text: episodio?.titulo);
    final descripcionController = TextEditingController(
      text: episodio?.descripcion,
    );
    final audioController = TextEditingController(text: episodio?.audio);

    XFile? imagen;
    bool guardando = false;
    String seccion = episodio?.seccion ?? _secciones.first;

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

                if (episodio == null && imagen == null) {
                  _mensaje('Selecciona una imagen para el podcast.');
                  return;
                }

                setSheetState(() => guardando = true);

                Reference? referencia;

                try {
                  final docId = episodio?.id ?? _episodios.doc().id;
                  String urlImagen = episodio?.imagen ?? '';

                  if (imagen != null) {
                    final extension = imagen!.name
                        .split('.')
                        .last
                        .toLowerCase();

                    final tipo = extension == 'png'
                        ? 'image/png'
                        : extension == 'webp'
                        ? 'image/webp'
                        : 'image/jpeg';

                    final sufijo =
                        ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
                        ? extension
                        : 'jpg';

                    referencia = FirebaseStorage.instance.ref(
                      'imagenes/podcast_$docId.$sufijo',
                    );

                    await referencia.putFile(
                      File(imagen!.path),
                      SettableMetadata(contentType: tipo),
                    );

                    urlImagen = await referencia.getDownloadURL();
                  }

                  final contenido = <String, dynamic>{
                    'titulo': tituloController.text.trim(),
                    'descripcion': descripcionController.text.trim(),
                    'audio': audioController.text.trim(),
                    'seccion': seccion,
                    'imagen': urlImagen,
                  };

                  if (episodio == null) {
                    await _episodios.doc(docId).set({
                      ...contenido,
                      'creadoEn': FieldValue.serverTimestamp(),
                    });
                  } else {
                    await _episodios.doc(docId).update(contenido);
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

                  _mensaje('No se pudo guardar el podcast: $e');

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
                            episodio == null
                                ? 'Nuevo podcast'
                                : 'Editar podcast',
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
                            controller: descripcionController,
                            enabled: !guardando,
                            minLines: 2,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                              alignLabelWithHint: true,
                            ),
                            validator: (valor) =>
                                valor == null || valor.trim().isEmpty
                                ? 'Ingresa una descripción'
                                : null,
                          ),

                          const SizedBox(height: AppSpacing.md16),

                          DropdownButtonFormField<String>(
                            initialValue: seccion,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Sección',
                            ),
                            items: _secciones
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
                                      setSheetState(() => seccion = valor);
                                    }
                                  },
                          ),

                          const SizedBox(height: AppSpacing.md16),

                          TextFormField(
                            controller: audioController,
                            enabled: !guardando,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(
                              labelText: 'URL del audio (mp3)',
                            ),
                            validator: (valor) =>
                                (valor ?? '').trim().startsWith('http')
                                ? null
                                : 'Ingresa un enlace que parta con http',
                          ),

                          const SizedBox(height: AppSpacing.md16),

                          // Vista previa de la imagen
                          if (imagen != null ||
                              (episodio?.imagen ?? '').isNotEmpty) ...[
                            _portada(
                              url: episodio?.imagen ?? '',
                              archivo: imagen,
                              proporcion: 1.85,
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
                              imagen == null && (episodio?.imagen ?? '').isEmpty
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
                              icon: guardando
                                  ? const SizedBox(
                                      width: AppSpacing.md16,
                                      height: AppSpacing.md16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: AppSpacing.xs4 / 2,
                                      ),
                                    )
                                  : const Icon(Icons.check),
                              label: Text(
                                guardando ? 'Guardando…' : 'Guardar podcast',
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
      descripcionController.dispose();
      audioController.dispose();
    }
  }

  Widget _tarjeta(List<Episodio> lista, int indice) {
    final episodio = lista[indice];

    return InkWell(
      onTap: () => _abrirReproductor(lista, indice),
      onLongPress: () => _opciones(episodio),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _portada(url: episodio.imagen),

          const SizedBox(height: AppSpacing.sm8),

          Text(
            episodio.titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.h5.copyWith(color: AppColors.neutral800),
          ),

          Text(
            episodio.descripcion,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body1.copyWith(color: AppColors.neutral600),
          ),
        ],
      ),
    );
  }

  Widget _seccion(String nombre, List<Episodio> lista) {
    final ancho = MediaQuery.sizeOf(context).width * _anchoTarjeta;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nombre,
          style: AppTypography.subtitle1.copyWith(color: AppColors.neutral800),
        ),

        const SizedBox(height: AppSpacing.md16),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < lista.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md16),
                  child: SizedBox(width: ancho, child: _tarjeta(lista, i)),
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md16),

        const Divider(color: AppColors.neutral300),

        const SizedBox(height: AppSpacing.md16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral100,

      floatingActionButton: FloatingActionButton(
        heroTag: null,
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.neutral100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShapes.radius24),
        ),
        tooltip: 'Agregar podcast',
        onPressed: () => _formulario(),
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'No se pudieron cargar los podcasts.',
                style: AppTypography.body2.copyWith(color: AppColors.error500),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final episodios = snapshot.data!.docs.map(Episodio.desde).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md16,
              AppSpacing.md16,
              AppSpacing.md16,
              AppSpacing.xxl48 + AppSpacing.xl32,
            ),
            children: [
              const SizedBox(height: AppSpacing.lg24),

              if (episodios.isEmpty)
                Text(
                  'Todavía no hay podcasts. Agrega el primero con el botón +',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),

              for (final nombre in _secciones)
                if (episodios.any((e) => e.seccion == nombre))
                  _seccion(
                    nombre,
                    episodios.where((e) => e.seccion == nombre).toList(),
                  ),
            ],
          );
        },
      ),
    );
  }
}


// reproductor
class ReproductorPodcastScreen extends StatefulWidget {
  const ReproductorPodcastScreen({
    super.key,
    required this.episodios,
    required this.indice,
  });

  final List<Episodio> episodios;
  final int indice;

  @override
  State<ReproductorPodcastScreen> createState() =>
      _ReproductorPodcastScreenState();
}

class _ReproductorPodcastScreenState extends State<ReproductorPodcastScreen> {
  final _player = AudioPlayer();

  late int _indice;
  bool _cargando = true;
  double _velocidad = 1.0;
  int? _minutosTimer;
  Timer? _temporizador;

  Episodio get _actual => widget.episodios[_indice];

  @override
  void initState() {
    super.initState();
    _indice = widget.indice;
    _cargar(_indice);
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _cargar(int indice) async {
    setState(() {
      _indice = indice;
      _cargando = true;
    });

    try {
      await _player.setUrl(widget.episodios[indice].audio);
      await _player.setSpeed(_velocidad);

      if (!mounted) return;
      setState(() => _cargando = false);

      _player.play();
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _mensaje('No se pudo reproducir el audio: $e');
    }
  }

  void _alternar() {
    if (_player.processingState == ProcessingState.completed) {
      _player.seek(Duration.zero);
      _player.play();
    } else if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _saltar(Duration desplazamiento) {
    final total = _player.duration ?? Duration.zero;
    var destino = _player.position + desplazamiento;

    if (destino < Duration.zero) destino = Duration.zero;
    if (total > Duration.zero && destino > total) destino = total;

    _player.seek(destino);
  }

  void _programarTimer(int? minutos) {
    _temporizador?.cancel();

    if (minutos == null) {
      setState(() => _minutosTimer = null);
      return;
    }

    _temporizador = Timer(Duration(minutes: minutos), () {
      _player.pause();
      if (mounted) setState(() => _minutosTimer = null);
    });

    setState(() => _minutosTimer = minutos);
  }

  void _elegirTimer() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.neutral100,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final minutos in const [5, 10, 15, 30, 60])
              ListTile(
                title: Text('$minutos minutos', style: AppTypography.body1),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _programarTimer(minutos);
                },
              ),
            ListTile(
              title: Text('Desactivar', style: AppTypography.body1),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _programarTimer(null);
              },
            ),
          ],
        ),
      ),
    );
  }

  // colores de los sliders
  SliderThemeData _temaSlider({required Color activo, required Color pulgar}) {
    return SliderTheme.of(context).copyWith(
      activeTrackColor: activo,
      inactiveTrackColor: AppColors.neutral200,
      thumbColor: pulgar,
      tickMarkShape: SliderTickMarkShape.noTickMark,
    );
  }

  // barra de progreso con tiempos a los lados
  Widget _progreso() {
    return StreamBuilder<Duration?>(
      stream: _player.durationStream,
      builder: (context, duracionSnap) {
        final total = duracionSnap.data ?? Duration.zero;

        return StreamBuilder<Duration>(
          stream: _player.positionStream,
          builder: (context, posicionSnap) {
            final posicion = posicionSnap.data ?? Duration.zero;

            final maximo = total.inMilliseconds > 0
                ? total.inMilliseconds.toDouble()
                : 1.0;

            final valor = posicion.inMilliseconds
                .toDouble()
                .clamp(0.0, maximo)
                .toDouble();

            return Row(
              children: [
                Text(
                  _formato(posicion),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.neutral400,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: _temaSlider(
                      activo: AppColors.secondary300,
                      pulgar: AppColors.secondary300,
                    ),
                    child: Slider(
                      value: valor,
                      max: maximo,
                      onChanged: (nuevo) =>
                          _player.seek(Duration(milliseconds: nuevo.round())),
                    ),
                  ),
                ),
                Text(
                  _formato(total),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.neutral400,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // botones anterior, retroceder 10 s, play/pausa, adelantar 10 s, siguiente
  Widget _controles() {
    final hayAnterior = _indice > 0;
    final haySiguiente = _indice < widget.episodios.length - 1;

    return IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.neutral600),
      ),
      child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: 'Anterior',
          onPressed: hayAnterior ? () => _cargar(_indice - 1) : null,
          icon: const Icon(Icons.skip_previous_outlined),
        ),
        IconButton(
          tooltip: 'Retroceder 10 segundos',
          onPressed: () => _saltar(const Duration(seconds: -10)),
          icon: const Icon(Icons.replay_10),
        ),
        StreamBuilder<PlayerState>(
          stream: _player.playerStateStream,
          builder: (context, snapshot) {
            final estado = snapshot.data;
            final reproduciendo =
                (estado?.playing ?? false) &&
                estado?.processingState != ProcessingState.completed;

            if (_cargando ||
                estado?.processingState == ProcessingState.loading ||
                estado?.processingState == ProcessingState.buffering) {
              return const IconButton(
                onPressed: null,
                iconSize: AppSpacing.xl32,
                icon: Icon(Icons.hourglass_empty),
              );
            }

            return IconButton(
              tooltip: reproduciendo ? 'Pausar' : 'Reproducir',
              onPressed: _alternar,
              iconSize: AppSpacing.xl32,
              icon: Icon(
                reproduciendo ? Icons.pause_outlined : Icons.play_arrow,
              ),
            );
          },
        ),
        IconButton(
          tooltip: 'Adelantar 10 segundos',
          onPressed: () => _saltar(const Duration(seconds: 10)),
          icon: const Icon(Icons.forward_10),
        ),
        IconButton(
          tooltip: 'Siguiente',
          onPressed: haySiguiente ? () => _cargar(_indice + 1) : null,
          icon: const Icon(Icons.skip_next_outlined),
        ),
      ],
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final episodio = _actual;

    final velocidadTexto = _velocidad == _velocidad.roundToDouble()
        ? '${_velocidad.round()}'
        : _velocidad.toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppColors.neutral100,

      appBar: AppBar(
        backgroundColor: AppColors.neutral100,
        foregroundColor: AppColors.secondary300,
        surfaceTintColor: Colors.transparent,
        elevation: AppSpacing.xs4,
        shadowColor: AppColors.tertiary100,
        title: Text(
          'Podcasts',
          style: AppTypography.h6.copyWith(color: AppColors.secondary300),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del podcast
            _portada(url: episodio.imagen, proporcion: 1.85),

            const SizedBox(height: AppSpacing.md16),

            Center(
              child: Text(
                episodio.seccion,
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary500,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm8),

            Text(
              episodio.titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.h5.copyWith(color: AppColors.neutral800),
            ),

            const SizedBox(height: AppSpacing.md16),

            _progreso(),

            const SizedBox(height: AppSpacing.md16),

            _controles(),

            const SizedBox(height: AppSpacing.lg24),

            // velocidad de reproducción
            Text(
              'Velocidad',
              style: AppTypography.overline.copyWith(
                color: AppColors.neutral700,
              ),
            ),

            Row(
              children: [
                const Icon(
                  Icons.slow_motion_video,
                  color: AppColors.neutral400,
                ),
                Expanded(
                  child: SliderTheme(
                    data: _temaSlider(
                      activo: AppColors.secondary100,
                      pulgar: AppColors.secondary200,
                    ),
                    child: Slider(
                      value: _velocidad,
                      min: 0.5,
                      max: 1.5,
                      divisions: 10,
                      onChanged: (nuevo) {
                        setState(() => _velocidad = nuevo);
                        _player.setSpeed(nuevo);
                      },
                    ),
                  ),
                ),
                const Icon(Icons.speed, color: AppColors.neutral400),
              ],
            ),

            Center(
              child: Text(
                '$velocidadTexto x speed',
                style: AppTypography.body2.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md16),

            // temporizador para pausar el audio
            Center(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  textStyle: AppTypography.button,
                  foregroundColor: AppColors.secondary300,
                  side: const BorderSide(color: AppColors.secondary300),
                ),
                onPressed: _elegirTimer,
                icon: const Icon(Icons.hourglass_empty),
                label: Text(
                  _minutosTimer == null ? 'Timer' : 'Timer · $_minutosTimer min',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}