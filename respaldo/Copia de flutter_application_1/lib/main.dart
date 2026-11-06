import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';
import 'theme/theme.dart';
import 'views/lists.dart';
import 'views/flash.dart';
import 'auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializar Google Sign-In
  await GoogleSignIn.instance.initialize();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: audiomack,
      home: const AuthGate(),
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
  String _categoriaSeleccionada = 'Today';

  // Categorías disponibles
  final List<String> _categorias = [
    'Today',
    'US',
    'Finance & Economics',
    'Business',
    'China',
    'Asia',
    'Europe',
    'Americas',
  ];

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
      ..showSnackBar(
        SnackBar(
          content: Text(
            texto,
            style: AppTypography.body2.copyWith(color: AppColors.neutral100),
          ),
        ),
      );
  }

  String _fecha(Timestamp? fecha) {
    if (fecha == null) return 'Fecha pendiente';

    final valor = fecha.toDate().toLocal();

    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(valor.day)}/${dos(valor.month)}/${valor.year}';
  }

  // Agregar una noticia
  Future<void> _agregarNoticia() async {
    final formKey = GlobalKey<FormState>();

    final tituloController = TextEditingController();
    final autorController = TextEditingController();
    final resumenController = TextEditingController();
    final textoController = TextEditingController();

    XFile? imagen;
    bool guardando = false;
    bool publicado = false;

    // Categoría inicial de la noticia
    String categoriaNoticia = 'US';

    try {
      await showModalBottomSheet<void>(
        backgroundColor: AppColors.neutral100,
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
                if (guardando || !formKey.currentState!.validate()) {
                  return;
                }

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

                  final sufijo =
                      ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
                      ? extension
                      : 'jpg';

                  referencia = FirebaseStorage.instance.ref(
                    'imagenes/$id.$sufijo',
                  );

                  await referencia.putFile(
                    File(imagen!.path),
                    SettableMetadata(contentType: tipo),
                  );

                  final url = await referencia.getDownloadURL();

                  // Guardar noticia en Firebase
                  await _articulos.doc(id).set({
                    'titulo': tituloController.text.trim(),
                    'autor': autorController.text.trim(),
                    'resumen': resumenController.text.trim(),
                    'texto': textoController.text.trim(),
                    'categoria': categoriaNoticia,
                    'imagen': url,
                    'imagenPath': referencia.fullPath,
                    'creadoEn': FieldValue.serverTimestamp(),
                  });

                  publicado = true;

                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
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
                          Text(
                            'Nueva noticia',
                            style: AppTypography.h6.copyWith(
                              color: AppColors.primary500,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md16),

                          // Título
                          TextFormField(
                            controller: tituloController,
                            style: AppTypography.body1.copyWith(
                              color: AppColors.neutral700,
                            ),
                            enabled: !guardando,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: 'Título',
                              labelStyle: AppTypography.subtitle1.copyWith(
                                color: AppColors.neutral600,
                              ),
                              floatingLabelStyle: AppTypography.subtitle1
                                  .copyWith(color: AppColors.primary500),
                              errorStyle: AppTypography.caption.copyWith(
                                color: AppColors.error500,
                              ),
                              filled: true,
                              fillColor: AppColors.tertiary100,
                              border: const OutlineInputBorder(),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.neutral300,
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.primary500,
                                  width: 2,
                                ),
                              ),
                              errorBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.error500,
                                ),
                              ),
                              focusedErrorBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.error500,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (valor) =>
                                valor == null || valor.trim().isEmpty
                                ? 'Ingresa un título'
                                : null,
                          ),

                          const SizedBox(height: AppSpacing.md16),

                          // Autor
                          TextFormField(
                            controller: autorController,
                            style: AppTypography.body1,
                            enabled: !guardando,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Autor',
                              labelStyle: AppTypography.subtitle1.copyWith(
                                color: AppColors.neutral600,
                              ),
                              floatingLabelStyle: AppTypography.subtitle1
                                  .copyWith(color: AppColors.primary500),
                              errorStyle: AppTypography.caption.copyWith(
                                color: AppColors.error500,
                              ),
                              filled: true,
                              fillColor: AppColors.tertiary100,
                              border: const OutlineInputBorder(),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.neutral300,
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.primary500,
                                  width: 2,
                                ),
                              ),
                              errorBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.error500,
                                ),
                              ),
                              focusedErrorBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.error500,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (valor) =>
                                valor == null || valor.trim().isEmpty
                                ? 'Ingresa el autor'
                                : null,
                          ),

                          const SizedBox(height: AppSpacing.md16),

                          // Selector de categoría
                          Text(
                            'Categoría',
                            style: AppTypography.subtitle1.copyWith(
                              color: AppColors.neutral700,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.sm8),

                          DropdownButtonFormField<String>(
                            initialValue: categoriaNoticia,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.tertiary100,
                              border: const OutlineInputBorder(),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.neutral300,
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.secondary300,
                                  width: 2,
                                ),
                              ),
                            ),
                            items: _categorias
                                .where((categoria) => categoria != 'Today')
                                .map((categoria) {
                                  return DropdownMenuItem<String>(
                                    value: categoria,
                                    child: Text(
                                      categoria,
                                      style: AppTypography.body1.copyWith(
                                        color: AppColors.neutral700,
                                      ),
                                    ),
                                  );
                                })
                                .toList(),
                            onChanged: guardando
                                ? null
                                : (valor) {
                                    if (valor != null) {
                                      setSheetState(() {
                                        categoriaNoticia = valor;
                                      });
                                    }
                                  },
                          ),

                          const SizedBox(height: AppSpacing.md16),

                          // Resumen
                          TextFormField(
                            controller: resumenController,
                            style: AppTypography.body1,
                            enabled: !guardando,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: 'Resumen',
                              labelStyle: AppTypography.subtitle1.copyWith(
                                color: AppColors.neutral600,
                              ),
                              floatingLabelStyle: AppTypography.subtitle1
                                  .copyWith(color: AppColors.primary500),
                              errorStyle: AppTypography.caption.copyWith(
                                color: AppColors.error500,
                              ),
                              filled: true,
                              fillColor: AppColors.tertiary100,
                              border: const OutlineInputBorder(),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.neutral300,
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.primary500,
                                  width: 2,
                                ),
                              ),
                              errorBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.error500,
                                ),
                              ),
                              focusedErrorBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.error500,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (valor) =>
                                valor == null || valor.trim().isEmpty
                                ? 'Ingresa un resumen'
                                : null,
                          ),

                          const SizedBox(height: AppSpacing.md16),

                          // Texto de la noticia
                          TextFormField(
                            controller: textoController,
                            style: AppTypography.body1,
                            enabled: !guardando,
                            minLines: 5,
                            maxLines: 8,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: 'Texto de la noticia',
                              alignLabelWithHint: true,
                              labelStyle: AppTypography.subtitle1.copyWith(
                                color: AppColors.neutral600,
                              ),
                              floatingLabelStyle: AppTypography.subtitle1
                                  .copyWith(color: AppColors.primary500),
                              errorStyle: AppTypography.caption.copyWith(
                                color: AppColors.error500,
                              ),
                              filled: true,
                              fillColor: AppColors.tertiary100,
                              border: const OutlineInputBorder(),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.neutral300,
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.primary500,
                                  width: 2,
                                ),
                              ),
                              errorBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.error500,
                                ),
                              ),
                              focusedErrorBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.error500,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (valor) =>
                                valor == null || valor.trim().isEmpty
                                ? 'Ingresa el texto'
                                : null,
                          ),

                          const SizedBox(height: AppSpacing.md16),

                          // Imagen seleccionada
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
                              imagen == null
                                  ? 'Seleccionar imagen'
                                  : 'Cambiar imagen',
                            ),
                          ),

                          const SizedBox(height: AppSpacing.sm8),

                          Text(
                            'Fecha: ${_fecha(Timestamp.now())}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.neutral500,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg24),

                          // Botón publicar
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                textStyle: AppTypography.button,
                                backgroundColor: AppColors.primary500,
                                foregroundColor: AppColors.neutral100,
                              ),
                              onPressed: guardando ? null : publicar,
                              icon: guardando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check),
                              label: Text(
                                guardando ? 'Publicando…' : 'Publicar noticia',
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

      if (publicado) {
        _mensaje('Noticia publicada correctamente');
      }
    } finally {
      // Esperar a que termine la animación de cierre del Bottom Sheet.
      await Future<void>.delayed(const Duration(milliseconds: 350));

      tituloController.dispose();
      autorController.dispose();
      resumenController.dispose();
      textoController.dispose();
    }
  }

  // Abrir detalle de una noticia
  void _abrirNoticia(Map<String, dynamic> noticia) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetalleNoticiaScreen(noticia: noticia),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral100,

      appBar: AppBar(
        backgroundColor: AppColors.neutral100,
        foregroundColor: AppColors.neutral700,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: Text(
          'The Economist',
          style: AppTypography.h5.copyWith(color: AppColors.primary500),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _selectedIndex = 1;
              });
            },
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md16),
        children: [
          // Chips de categorías: solo aparecen en la pantalla principal.
          if (_selectedIndex == 0) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categorias.map((categoria) {
                  final seleccionada = _categoriaSeleccionada == categoria;

                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm8),
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
          ],

          Text(
            _selectedIndex == 1 ? 'Buscar noticias' : 'TOP STORIES',
            textAlign: TextAlign.center,
            style: AppTypography.subtitle1.copyWith(
              color: AppColors.primary500,
            ),
          ),

          const SizedBox(height: AppSpacing.md16),

          // Buscador
          if (_selectedIndex == 1) ...[
            TextField(
              controller: _busquedaController,
              style: AppTypography.body1.copyWith(color: AppColors.neutral700),
              onChanged: (valor) {
                setState(() {
                  _busqueda = valor.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar por título o autor',
                hintStyle: AppTypography.body2.copyWith(
                  color: AppColors.neutral500,
                ),
                prefixIcon: Icon(Icons.search, color: AppColors.secondary300),
                filled: true,
                fillColor: AppColors.neutral100,
                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.neutral300),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.secondary300,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md16),
          ],

          // Cargar noticias desde Firebase
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
                return const Center(child: CircularProgressIndicator());
              }

              // Filtrar noticias por categoría o búsqueda.
              final documentos = snapshot.data!.docs.where((doc) {
                final datos = doc.data();

                // Filtro de categorías
                if (_selectedIndex == 0 && _categoriaSeleccionada != 'Today') {
                  final categoria = (datos['categoria'] ?? '').toString();

                  if (categoria != _categoriaSeleccionada) {
                    return false;
                  }
                }

                // Filtro de búsqueda
                if (_selectedIndex == 1 && _busqueda.isNotEmpty) {
                  final titulo = (datos['titulo'] ?? '')
                      .toString()
                      .toLowerCase();

                  final autor = (datos['autor'] ?? '').toString().toLowerCase();

                  return titulo.contains(_busqueda) ||
                      autor.contains(_busqueda);
                }

                return true;
              }).toList();

              // Mensaje cuando no hay resultados
              if (documentos.isEmpty) {
                String mensajeVacio;

                if (_selectedIndex == 1 && _busqueda.isNotEmpty) {
                  mensajeVacio = 'No se encontraron noticias.';
                } else if (_selectedIndex == 0 &&
                    _categoriaSeleccionada != 'Today') {
                  mensajeVacio = 'No hay noticias en esta categoría todavía.';
                } else {
                  mensajeVacio = 'Todavía no hay noticias publicadas.';
                }

                return Text(
                  mensajeVacio,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.neutral600,
                  ),
                );
              }

              // Mostrar noticias
              return Column(
                children: documentos.map((doc) {
                  final noticia = doc.data();

                  final imagen = noticia['imagen'] as String? ?? '';

                  final titulo = noticia['titulo'] as String? ?? 'Sin título';

                  final resumen = noticia['resumen'] as String? ?? '';

                  return Card(
                    color: AppColors.neutral100,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _abrirNoticia(noticia),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AspectRatio(
                                aspectRatio: 1.85,
                                child: imagen.isEmpty
                                    ? ColoredBox(
                                        color: AppColors.tertiary200,
                                        child: const Icon(
                                          Icons.image_outlined,
                                          color: AppColors.neutral600,
                                        ),
                                      )
                                    : Image.network(
                                        imagen,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.broken_image_outlined,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // titulo
                            Text(
                              titulo,
                              style: AppTypography.h5.copyWith(
                                color: AppColors.neutral800,
                                fontSize: 28,
                                height: 1.2,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // resumen
                            Text(
                              resumen,
                              style: AppTypography.subtitle2.copyWith(
                                color: AppColors.neutral600,
                                fontSize: 20,
                                height: 1.3,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // fecha
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 22,
                                  color: AppColors.neutral500,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _fecha(noticia['creadoEn'] as Timestamp?),
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.neutral500,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
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
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.neutral100,
        onPressed: _agregarNoticia,
        tooltip: 'Agregar noticia',
        child: const Icon(Icons.add),
      ),

      bottomNavigationBar: NavigationBar(
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (states) => AppTypography.caption.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.secondary600
                : AppColors.neutral600,
          ),
        ),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const ListsView()));
            return;
          }

          if (index == 3) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const FlashView()));
            return;
          }

          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.groups_outlined, color: AppColors.neutral600),
            selectedIcon: Icon(Icons.groups, color: AppColors.secondary600),
            label: 'Comunidad',
          ),

          NavigationDestination(
            icon: Icon(Icons.search_outlined, color: AppColors.neutral600),
            selectedIcon: Icon(Icons.search, color: AppColors.secondary600),
            label: 'Buscar',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.format_list_bulleted_outlined,
              color: AppColors.neutral600,
            ),
            selectedIcon: Icon(
              Icons.format_list_bulleted,
              color: AppColors.secondary600,
            ),
            label: 'Listas',
          ),

          NavigationDestination(
            icon: Icon(Icons.flash_on_outlined, color: AppColors.neutral600),
            selectedIcon: Icon(Icons.flash_on, color: AppColors.secondary600),
            label: 'Flash',
          ),
        ],
      ),
    );
  }
}

// Pantalla de detalle de una noticia
class DetalleNoticiaScreen extends StatelessWidget {
  const DetalleNoticiaScreen({super.key, required this.noticia});

  final Map<String, dynamic> noticia;

  @override
  Widget build(BuildContext context) {
    final imagen = noticia['imagen'] as String? ?? '';
    final fecha = noticia['creadoEn'] as Timestamp?;

    final fechaTexto = fecha == null
        ? 'Fecha pendiente'
        : '${fecha.toDate().toLocal().day.toString().padLeft(2, '0')}/'
              '${fecha.toDate().toLocal().month.toString().padLeft(2, '0')}/'
              '${fecha.toDate().toLocal().year}';

    return Scaffold(
      backgroundColor: AppColors.tertiary100,

      appBar: AppBar(
        backgroundColor: AppColors.neutral100,
        foregroundColor: AppColors.neutral700,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Noticia',
          style: AppTypography.h6.copyWith(color: AppColors.primary500),
        ),
      ),

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
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 180,
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg24),
          ],

          Text(
            noticia['titulo'] as String? ?? 'Sin título',
            style: AppTypography.h5.copyWith(color: AppColors.neutral700),
          ),

          const SizedBox(height: AppSpacing.sm8),

          Text(
            '${noticia['autor'] ?? 'Autor desconocido'} · $fechaTexto',
            style: AppTypography.caption.copyWith(color: AppColors.neutral500),
          ),

          const SizedBox(height: AppSpacing.lg24),

          Text(
            noticia['resumen'] as String? ?? '',
            style: AppTypography.subtitle1.copyWith(
              color: AppColors.secondary600,
            ),
          ),

          const SizedBox(height: AppSpacing.md16),

          Text(
            noticia['texto'] as String? ?? '',
            style: AppTypography.body1.copyWith(color: AppColors.neutral700),
          ),
        ],
      ),
    );
  }
}
