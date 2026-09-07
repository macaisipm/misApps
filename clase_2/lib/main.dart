import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF005293),

          leading: IconButton(
            icon: const Icon(Icons.menu),
            color: Colors.white,
            onPressed: () {},
            ),

          title: const Text(
            'Clase uno',
            style: TextStyle(
              color: Colors.white,)
              ),

              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ),

                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'perfil',
                      child: Row(
                        children: [
                          Icon(Icons.account_circle),
                          SizedBox(width: 10),
                          Text('Perfil'),
                        ],
                      ),
                    ),

                    const PopupMenuItem<String>(
                      value: 'configuration',
                      child: Row(
                        children: [
                          Icon(Icons.settings),
                          SizedBox(width: 10),
                          Text('Configuration'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
        ),

        body: ListView(
            children: [

            Container(
              height: 200,
              width: double.infinity,
              color: const Color.fromARGB(255, 0, 0, 0),

              child: const Center(
                child: Text(
                  'Container 1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ),

            SizedBox(height: 8.0),

            Container(
              height: 400,
              width: double.infinity,

              margin: const EdgeInsets.all(16.0),

              padding: const EdgeInsets.all(40.0),

              color: Color.fromRGBO(20, 82, 147, 1),

              child: Container(
                color: Colors.white,
                child: Text(
                  'Container 2',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 24,
                  ),
                ),
              ),
            ),

            SizedBox(height: 8.0),

            //container expanded
            Container(
              height: 400,
              width: double.infinity,

              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
              ),

              color: const Color.fromARGB(255, 251, 251, 251),

              child: Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Expanded(
                    child: Container(
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      

                      child: const Center(
                        child: Text(
                          'Izquierda',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ),
                  ),
                  ),

                  SizedBox(width: 8.0,),

                  Expanded(
                    child: Container(
                      color: Colors.blue,

                      child: const Center(
                        child: Text(
                          'Derecha',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                    ),

                  SizedBox(width: 8.0,),

                    Expanded(
                    child: Container(
                      color: Colors.yellow,

                      child: const Center(
                        child: Text(
                          'Centro',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                    ),
                ],
              ),
            ),
            ],
        ),

        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,

          items: const [

            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'Mensajes',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Buscar',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Perfil',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Inicio',
            ),
          ],
        ),
      ),
    );
  }
}