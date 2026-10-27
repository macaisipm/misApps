import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'firebase_options.dart';
import 'theme/theme.dart';
import 'views/lists.dart';
import 'views/flash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: audiomack,
      home: const NoticiasScreen(),
    );
  }
}

class NoticiasScreen extends StatefulWidget {
  const NoticiasScreen({super.key});

  @override
  State<NoticiasScreen> createState() => _NoticiasScreenState();
}

class _NoticiasScreenState extends State<NoticiasScreen> {
  final _articulos = FirebaseFirestore.instance.collection('articulo');
  final _busquedaController = TextEditingController();
  final _picker = ImagePicker();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _noticiasStream;
  int _selectedIndex = 0;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _noticiasStream = _articulos
        .orderBy('creadoEn', descending: true)
        .limit(50)
        .snapshots();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  String _fecha(Timestamp? fecha) {
    if (fecha == null) return 'Fecha pendiente';
    final valor = fecha.toDate().toLocal();
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(valor.day)}/${dos(valor.month)}/${valor.year}';
  }

  Future<void> _agregarNoticia() async {
    final formKey = GlobalKey<FormState>();
    final tituloController = TextEditingController();
    final autorController = TextEditingController();
    final resumenController = TextEditingController();
    final textoController = TextEditingController();
    XFile? imagen;
    bool guardando = false;
    bool publicado = false;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
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

              Future<void> publicar() async {
                if (guardando || !formKey.currentState!.validate()) return;
                if (imagen == null) {
                  _mensaje('Selecciona una imagen para la noticia.');
                  return;
                }
                setSheetState(() => guardando = true);
                Reference? referencia;
                try {
                  final id = _articulos.doc().id;
                  final extension = imagen!.name.split('.').last.toLowerCase();
                  final tipo = extension == 'png'
                      ? 'image/png'
                      : extension == 'webp'
                          ? 'image/webp'
                          : 'image/jpeg';
                  final sufijo = ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
                      ? extension
                      : 'jpg';
                  referencia = FirebaseStorage.instance.ref('imagenes/$id.$sufijo');
                  await referencia.putFile(
                    File(imagen!.path),
                    SettableMetadata(contentType: tipo),
                  );
                  final url = await referencia.getDownloadURL();
                  await _articulos.doc(id).set({
                    'titulo': tituloController.text.trim(),
                    'autor': autorController.text.trim(),
                    'resumen': resumenController.text.trim(),
                    'texto': textoController.text.trim(),
                    'imagen': url,
                    'imagenPath': referencia.fullPath,
                    'creadoEn': FieldValue.serverTimestamp(),
                  });
                  publicado = true;
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                } catch (e) {
                  if (referencia != null) {
                    try {
                      await referencia.delete();
                    } catch (_) {}
                  }
                  _mensaje('No se pudo publicar la noticia: $e');
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
                          Text('Nueva noticia',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: AppSpacing.md16),
                          TextFormField(
                            controller: tituloController,
                            enabled: !guardando,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Título',
                              border: OutlineInputBorder(),
                            ),
                            validator: (valor) => valor == null || valor.trim().isEmpty
                                ? 'Ingresa un título'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md16),
                          TextFormField(
                            controller: autorController,
                            enabled: !guardando,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Autor',
                              border: OutlineInputBorder(),
                            ),
                            validator: (valor) => valor == null || valor.trim().isEmpty
                                ? 'Ingresa el autor'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md16),
                          TextFormField(
                            controller: resumenController,
                            enabled: !guardando,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Resumen',
                              border: OutlineInputBorder(),
                            ),
                            validator: (valor) => valor == null || valor.trim().isEmpty
                                ? 'Ingresa un resumen'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md16),
                          TextFormField(
                            controller: textoController,
                            enabled: !guardando,
                            minLines: 5,
                            maxLines: 8,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Texto de la noticia',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(),
                            ),
                            validator: (valor) => valor == null || valor.trim().isEmpty
                                ? 'Ingresa el texto'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md16),
                          if (imagen != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(imagen!.path),
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm8),
                          ],
                          OutlinedButton.icon(
                            onPressed: guardando ? null : seleccionarImagen,
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                            label: Text(imagen == null
                                ? 'Seleccionar imagen'
                                : 'Cambiar imagen'),
                          ),
                          const SizedBox(height: AppSpacing.sm8),
                          Text('Fecha: ${_fecha(Timestamp.now())}',
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: AppSpacing.lg24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: guardando ? null : publicar,
                              icon: guardando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.check),
                              label: Text(guardando ? 'Publicando…' : 'Publicar noticia'),
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
      if (publicado) _mensaje('Noticia publicada correctamente');
    } finally {
      // Esperar a que termine la animación de cierre del Bottom Sheet.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      tituloController.dispose();
      autorController.dispose();
      resumenController.dispose();
      textoController.dispose();
    }
  }

  void _abrirNoticia(Map<String, dynamic> noticia) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetalleNoticiaScreen(noticia: noticia),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: const Text('The Economist'),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() => _selectedIndex = 1))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md16),
        children: [
          Text(_selectedIndex == 1 ? 'Buscar noticias' : 'Últimas noticias',
              style: textos.headlineLarge),
          const SizedBox(height: AppSpacing.md16),
          if (_selectedIndex == 1) ...[
            TextField(
              controller: _busquedaController,
              onChanged: (valor) => setState(() => _busqueda = valor.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Buscar por título o autor',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md16),
          ],
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _noticiasStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('No se pudieron cargar las noticias.');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final documentos = snapshot.data!.docs.where((doc) {
                if (_selectedIndex != 1 || _busqueda.isEmpty) return true;
                final datos = doc.data();
                return (datos['titulo'] ?? '').toString().toLowerCase().contains(_busqueda) ||
                    (datos['autor'] ?? '').toString().toLowerCase().contains(_busqueda);
              }).toList();
              if (documentos.isEmpty) {
                return Text(_busqueda.isNotEmpty && _selectedIndex == 1
                    ? 'No se encontraron noticias.'
                    : 'Todavía no hay noticias publicadas.');
              }
              return Column(
                children: documentos.map((doc) {
                  final noticia = doc.data();
                  final imagen = noticia['imagen'] as String? ?? '';
                  final titulo = noticia['titulo'] as String? ?? 'Sin título';
                  final resumen = noticia['resumen'] as String? ?? '';
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _abrirNoticia(noticia),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm8),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 96,
                                height: 96,
                                child: imagen.isEmpty
                                    ? ColoredBox(
                                        color: colores.surfaceContainerHighest,
                                        child: const Icon(Icons.image_outlined),
                                      )
                                    : Image.network(
                                        imagen,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            const Icon(Icons.broken_image_outlined),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    titulo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textos.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.xs4),
                                  Text(
                                    resumen,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: textos.bodySmall,
                                  ),
                                  const SizedBox(height: AppSpacing.xs4),
                                  Text(
                                    _fecha(noticia['creadoEn'] as Timestamp?),
                                    style: textos.labelSmall?.copyWith(
                                      color: colores.onSurfaceVariant,
                                    ),
                                  ),
                                ],
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarNoticia,
        tooltip: 'Agregar noticia',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ListsView()),
            );
            return;
          }
          if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const FlashView()),
            );
            return;
          }
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Comunidad',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(Icons.format_list_bulleted_outlined),
            selectedIcon: Icon(Icons.format_list_bulleted),
            label: 'Listas',
          ),
          NavigationDestination(
            icon: Icon(Icons.flash_on_outlined),
            selectedIcon: Icon(Icons.flash_on),
            label: 'Flash',
          ),
        ],
      ),
    );
  }
}

class DetalleNoticiaScreen extends StatelessWidget {
  const DetalleNoticiaScreen({super.key, required this.noticia});

  final Map<String, dynamic> noticia;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final imagen = noticia['imagen'] as String? ?? '';
    final fecha = noticia['creadoEn'] as Timestamp?;
    final fechaTexto = fecha == null
        ? 'Fecha pendiente'
        : '${fecha.toDate().toLocal().day.toString().padLeft(2, '0')}/'
            '${fecha.toDate().toLocal().month.toString().padLeft(2, '0')}/'
            '${fecha.toDate().toLocal().year}';

    return Scaffold(
      appBar: AppBar(title: const Text('Noticia')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md16),
        children: [
          if (imagen.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imagen,
                height: 230,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 180,
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg24),
          ],
          Text(noticia['titulo'] as String? ?? 'Sin título',
              style: textos.headlineMedium),
          const SizedBox(height: AppSpacing.sm8),
          Text('${noticia['autor'] ?? 'Autor desconocido'} · $fechaTexto',
              style: textos.bodySmall),
          const SizedBox(height: AppSpacing.lg24),
          Text(noticia['resumen'] as String? ?? '',
              style: textos.titleMedium),
          const SizedBox(height: AppSpacing.md16),
          Text(noticia['texto'] as String? ?? '', style: textos.bodyLarge),
        ],
      ),
    );
  }
}
