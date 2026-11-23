import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum TipoGuardado {
  noticia('articulo', 'guardadas', 'Noticia'),
  video('video', 'videosGuardados', 'Video'),
  podcast('podcast', 'podcastsGuardados', 'Podcast');

  const TipoGuardado(this.coleccion, this.campo, this.etiqueta);

  final String coleccion;
  final String campo;
  final String etiqueta;
}

List<String> idsGuardados(Map<String, dynamic>? datos, TipoGuardado tipo) {
  final ids = datos?[tipo.campo];
  return ids is List
      ? ids.whereType<String>().where((id) => id.isNotEmpty).toList()
      : const [];
}

class BotonGuardar extends StatefulWidget {
  const BotonGuardar({
    super.key,
    required this.noticiaId,
    this.tipo = TipoGuardado.noticia,
    this.color,
    this.iconoSinGuardar,
    this.iconSize,
    this.visualDensity = VisualDensity.compact,
  });

  final String noticiaId;
  final TipoGuardado tipo;
  final Color? color;
  final Widget? iconoSinGuardar;
  final double? iconSize;
  final VisualDensity? visualDensity;

  @override
  State<BotonGuardar> createState() => _BotonGuardarState();
}

class _BotonGuardarState extends State<BotonGuardar> {
  late final _uid = FirebaseAuth.instance.currentUser?.uid;
  late final _ref = _uid == null
      ? null
      : FirebaseFirestore.instance.collection('usuarios').doc(_uid);
  late final _stream = _ref?.snapshots();
  bool _guardando = false;

  Future<void> _cambiar(bool guardado) async {
    final ref = _ref;
    if (ref == null || _guardando) return;

    setState(() => _guardando = true);
    try {
      await ref.set({
        widget.tipo.campo: guardado
            ? FieldValue.arrayRemove([widget.noticiaId])
            : FieldValue.arrayUnion([widget.noticiaId]),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el marcador: ${e.code}')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ref == null || widget.noticiaId.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        final guardado = idsGuardados(snapshot.data?.data(), widget.tipo)
            .contains(widget.noticiaId);

        return IconButton(
          tooltip: snapshot.hasError
              ? 'No se pudieron cargar los marcadores'
              : guardado
                  ? 'Quitar de Bookmarks'
                  : 'Guardar en Bookmarks',
          visualDensity: widget.visualDensity,
          iconSize: widget.iconSize,
          onPressed: snapshot.hasData && !_guardando
              ? () => _cambiar(guardado)
              : null,
          icon: guardado
              ? const Icon(Icons.bookmark)
              : (widget.iconoSinGuardar ?? const Icon(Icons.bookmark_border)),
          color: widget.color ??
              (guardado ? AppColors.secondary300 : AppColors.neutral600),
        );
      },
    );
  }
}
