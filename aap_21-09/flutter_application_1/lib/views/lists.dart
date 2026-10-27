import 'package:flutter/material.dart';

class ListsView extends StatelessWidget {
  const ListsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listas'),
      ),
      body: const Center(
        child: Text('Aquí aparecerán tus listas'),
      ),
    );
  }
}