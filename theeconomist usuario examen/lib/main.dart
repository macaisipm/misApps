import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/views/user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'firebase_options.dart';
import 'theme/theme.dart';
import 'views/podcasts.dart';
import 'views/weekly.dart';
import 'views/video.dart';
import 'auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    await GoogleSignIn.instance.initialize();
  }

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

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _noticiasStream;

  int _selectedIndex = 0;
  bool _mostrandoBuscador = false;
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

  String _fecha(Timestamp? fecha) {
    if (fecha == null) return 'Fecha pendiente';

    final valor = fecha.toDate().toLocal();

    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(valor.day)}/${dos(valor.month)}/${valor.year}';
  }

  // Abrir detalle de una noticia
  void _abrirNoticia(Map<String, dynamic> noticia) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetalleNoticiaScreen(noticia: noticia),
      ),
    );
  }

  Widget _buildHome() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md16),
      children: [
        // Chips de categorías
        if (!_mostrandoBuscador) ...[
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
          _mostrandoBuscador ? 'Buscar noticias' : 'TOP STORIES',
          textAlign: TextAlign.center,
          style: AppTypography.subtitle1.copyWith(color: AppColors.primary500),
        ),

        const SizedBox(height: AppSpacing.md16),

        // Buscador
        if (_mostrandoBuscador) ...[
          TextField(
            controller: _busquedaController,
            cursorColor: AppColors.secondary300,
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
                borderSide: BorderSide(color: AppColors.secondary300, width: 2),
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
                style: AppTypography.body2.copyWith(color: AppColors.error500),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Filtrar noticias por categoría o búsqueda.
            final documentos = snapshot.data!.docs.where((doc) {
              final datos = doc.data();

              // Filtro de categorías
              if (!_mostrandoBuscador && _categoriaSeleccionada != 'Today') {
                final categoria = (datos['categoria'] ?? '').toString();

                if (categoria != _categoriaSeleccionada) {
                  return false;
                }
              }

              // Filtro de búsqueda
              if (_mostrandoBuscador && _busqueda.isNotEmpty) {
                final titulo = (datos['titulo'] ?? '').toString().toLowerCase();

                final autor = (datos['autor'] ?? '').toString().toLowerCase();

                return titulo.contains(_busqueda) || autor.contains(_busqueda);
              }

              return true;
            }).toList();

            // Mensaje cuando no hay resultados
            if (documentos.isEmpty) {
              String mensajeVacio;

              if (_mostrandoBuscador && _busqueda.isNotEmpty) {
                mensajeVacio = 'No se encontraron noticias.';
              } else if (!_mostrandoBuscador &&
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

                final tema = noticia['categoria'] as String? ?? '';

                return Card(
                  color: AppColors.neutral100,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _abrirNoticia({...noticia, 'id': doc.id}),
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
                                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.broken_image_outlined,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

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

                          const SizedBox(height: 16),

                          // resumen
                          Text(
                            resumen,
                            style: AppTypography.subtitle2.copyWith(
                              color: AppColors.neutral600,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // fecha
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
                                  _fecha(noticia['creadoEn'] as Timestamp?),
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

                              BotonGuardar(noticiaId: doc.id),
                            ],
                          ),

                          //divider
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppMargin.relaxed24,
                            ),
                            child: const Divider(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral100,

      appBar: AppBar(
        backgroundColor: AppColors.neutral100,
        foregroundColor: AppColors.neutral700,
        surfaceTintColor: Colors.transparent,

        elevation: 4,
        shadowColor: AppColors.tertiary100,

        leading: _selectedIndex == 0
            ? IconButton(icon: const Icon(Icons.menu), onPressed: () {})
            : null,
        automaticallyImplyLeading: false,

        title: Text(
          const [
            'The Economist',
            'Weekly',
            'Podcast',
            'Video',
            'User',
          ][_selectedIndex],
          style: _selectedIndex == 0
              ? AppTypography.h5.copyWith(color: AppColors.primary500)
              : AppTypography.h5.copyWith(
                  color: AppColors.neutral800,
                  fontWeight: FontWeight.w600,
                ),
        ),

        centerTitle: _selectedIndex == 0,
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: Icon(_mostrandoBuscador ? Icons.close : Icons.search),
              tooltip: _mostrandoBuscador
                  ? 'Cerrar búsqueda'
                  : 'Buscar noticias',
              onPressed: () {
                setState(() {
                  _mostrandoBuscador = !_mostrandoBuscador;
                  _busqueda = '';
                  _busquedaController.clear();
                });
              },
            ),
        ],
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHome(),
          WeeklyView(onAbrirNoticia: _abrirNoticia),
          const PodcastsView(),
          const VideoView(),
          UserView(onAbrirNoticia: _abrirNoticia),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (states) => AppTypography.caption.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary500
                : AppColors.neutral400,
          ),
        ),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          FocusScope.of(context).unfocus();
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: SvgPicture.asset(
              'assets/iconos/home.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.neutral400,
                BlendMode.srcIn,
              ),
            ),
            selectedIcon: SvgPicture.asset(
              'assets/iconos/home.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.primary500,
                BlendMode.srcIn,
              ),
            ),
            label: 'Home',
          ),

          NavigationDestination(
            icon: SvgPicture.asset(
              'assets/iconos/weekly.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.neutral400,
                BlendMode.srcIn,
              ),
            ),
            selectedIcon: SvgPicture.asset(
              'assets/iconos/weekly.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.primary500,
                BlendMode.srcIn,
              ),
            ),
            label: 'Weekly',
          ),

          NavigationDestination(
            icon: SvgPicture.asset(
              'assets/iconos/podcast.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.neutral400,
                BlendMode.srcIn,
              ),
            ),
            selectedIcon: SvgPicture.asset(
              'assets/iconos/podcast.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.primary500,
                BlendMode.srcIn,
              ),
            ),
            label: 'Podcast',
          ),

          NavigationDestination(
            icon: SvgPicture.asset(
              'assets/iconos/video.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.neutral400,
                BlendMode.srcIn,
              ),
            ),
            selectedIcon: SvgPicture.asset(
              'assets/iconos/video.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.primary500,
                BlendMode.srcIn,
              ),
            ),
            label: 'Video',
          ),

          NavigationDestination(
            icon: SvgPicture.asset(
              'assets/iconos/user.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.neutral400,
                BlendMode.srcIn,
              ),
            ),
            selectedIcon: SvgPicture.asset(
              'assets/iconos/user.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.primary500,
                BlendMode.srcIn,
              ),
            ),
            label: 'User',
          ),
        ],
      ),
    );
  }
}

// detalle de la noticia
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
      backgroundColor: AppColors.neutral100,

      //appbar noticia detallada
      appBar: AppBar(
        backgroundColor: AppColors.neutral100,
        foregroundColor: AppColors.neutral700,
        surfaceTintColor: Colors.transparent,

        elevation: 4,
        shadowColor: AppColors.tertiary100,

        //retroceder icono
        leading: IconButton(
          tooltip: 'Volver',
          icon: SvgPicture.asset(
            'assets/iconos/retroceder.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              AppColors.secondary300,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),

        title: Text(
          'Home',
          style: AppTypography.h6.copyWith(color: AppColors.secondary300),
        ),

        actions: [
          SvgPicture.asset(
            'assets/iconos/letra.svg',
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              AppColors.secondary300,
              BlendMode.srcIn,
            ),
          ),

          const SizedBox(width: AppGap.spacious16),

          if (noticia['id'] case final String id)
            BotonGuardar(
              noticiaId: id,
              iconoSinGuardar: SvgPicture.asset(
                'assets/iconos/bookmark.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AppColors.secondary300,
                  BlendMode.srcIn,
                ),
              ),
            )
          else
            SvgPicture.asset(
              'assets/iconos/bookmark.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.secondary300,
                BlendMode.srcIn,
              ),
            ),

          const SizedBox(width: AppGap.spacious16),

          SvgPicture.asset(
            'assets/iconos/share.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              AppColors.secondary300,
              BlendMode.srcIn,
            ),
          ),

          const SizedBox(width: AppGap.spacious16),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md16),
        children: [
          //caption detalle noticia
          Text(
            noticia['categoria'] as String? ?? 'Sin título',
            style: AppTypography.overline.copyWith(color: AppColors.primary500),
          ),

          const SizedBox(height: AppSpacing.md16),

          //titulo detalle noticia
          Text(
            noticia['titulo'] as String? ?? 'Sin título',
            style: AppTypography.h5.copyWith(color: AppColors.neutral700),
          ),

          const SizedBox(height: AppSpacing.md16),

          //resumen detalle noticia
          Text(
            noticia['resumen'] as String? ?? '',
            style: AppTypography.subtitle1.copyWith(
              color: AppColors.neutral600,
            ),
          ),

          const SizedBox(height: AppSpacing.md16),

          //imagen
          if (imagen.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imagen,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                height: 230,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 180,
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md16),
          ],

          // autor detalle noticia
          Text(
            '${noticia['autor'] ?? 'Autor desconocido'} · $fechaTexto',
            style: AppTypography.caption.copyWith(color: AppColors.neutral600),
          ),

          const SizedBox(height: AppSpacing.md16),

          Divider(color: AppColors.neutral300, thickness: 2, height: 1),

          const SizedBox(height: AppSpacing.md16),

          // noticia detallada
          Text(
            noticia['texto'] as String? ?? '',
            style: AppTypography.body1.copyWith(color: AppColors.neutral800),
          ),
        ],
      ),

      floatingActionButton: SizedBox(
        width: 40,
        height: 40,
        child: FloatingActionButton(
          backgroundColor: AppColors.secondary300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShapes.radius24),
          ),
          onPressed: () {},
          tooltip: 'Escuchar noticia',
          child: SvgPicture.asset(
            'assets/iconos/video.svg',
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              AppColors.neutral100,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}