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
            icon: const Icon(Icons.arrow_back),
            color: Colors.white,
            onPressed: () {},
            ),

          title: const Text(
            'Busqueda',
            style: TextStyle(
              color: Colors.white,)
              ),
        ),

        body: ListView(
            children: [

            Container(
              height: 40,
              width: double.infinity,
              color: const Color.fromARGB(255, 118, 117, 117),

              child: const Center(
                child: Text(
                  'menu deslizable',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            SizedBox(height: 5.0),

            //container expanded
            Container(
              height: 350,
              width: double.infinity,

              margin: const EdgeInsets.symmetric(
                horizontal: 12.0,
              ),

              color: const Color.fromARGB(255, 251, 251, 251),

              child: Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Expanded(
                    child: Container(
                      color: Colors.blue,

                      margin: EdgeInsets.symmetric(
                        horizontal: 2.0,
                      ),

                      child: const Center(
                        child: Text(
                          'video 1',
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

                      margin: EdgeInsets.symmetric(
                        horizontal: 2.0,
                      ),

                      child: const Center(
                        child: Text(
                          'video 2',
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
            
            // texto debajo del video
            SizedBox(height: 8.0,),
           
             Container(
              height: 50,
              width: double.infinity,

              margin: const EdgeInsets.symmetric(
                horizontal: 12.0,
              ),

              color: const Color.fromARGB(255, 251, 251, 251),

              child: Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Expanded(
                    child: Container(
                      color: const Color.fromARGB(255, 243, 93, 33),

                      margin: EdgeInsets.symmetric(
                        horizontal: 2.0,
                      ),

                      child: const Center(
                        child: Text(
                          'texto debajo',
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
                      color: const Color.fromARGB(255, 239, 216, 3),

                      margin: EdgeInsets.symmetric(
                        horizontal: 2.0,
                      ),

                      child: const Center(
                        child: Text(
                          'texto debajo',
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

            // segunda linea 
            Container(

              height: 350,
              width: double.infinity,

              margin: const EdgeInsets.all(12.0),

              color: const Color.fromARGB(255, 251, 251, 251),

              child: Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Expanded(
                    child: Container(
                      color: Colors.blue,

                      margin: EdgeInsets.symmetric(
                        horizontal: 2.0,
                      ),

                      child: const Center(
                        child: Text(
                          'video 3',
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

                      margin: EdgeInsets.symmetric(
                        horizontal: 2.0,
                      ),

                      child: const Center(
                        child: Text(
                          'video 4',
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
            
            // texto debajo del video
            SizedBox(height: 8.0,),
           
             Container(
              height: 50,
              width: double.infinity,

              margin: const EdgeInsets.symmetric(
                horizontal: 12.0,
              ),

              color: const Color.fromARGB(255, 251, 251, 251),

              child: Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Expanded(
                    child: Container(
                      color: const Color.fromARGB(255, 243, 93, 33),

                      margin: EdgeInsets.symmetric(
                        horizontal: 2.0,
                      ),

                      child: const Center(
                        child: Text(
                          'texto debajo',
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
                      color: const Color.fromARGB(255, 239, 216, 3),

                      margin: EdgeInsets.symmetric(
                        horizontal: 2.0,
                      ),

                      child: const Center(
                        child: Text(
                          'texto debajo',
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

            //tercera linea
            // segunda linea 
            Container(

              height: 350,
              width: double.infinity,

              margin: const EdgeInsets.all(12.0),

              color: const Color.fromARGB(255, 251, 251, 251),

              child: Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Expanded(
                    child: Container(
                      color: Colors.blue,

                      margin: EdgeInsets.symmetric(
                        horizontal: 2.0,
                      ),

                      child: const Center(
                        child: Text(
                          'video 5',
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

                      margin: EdgeInsets.symmetric(
                        horizontal: 2.0,
                      ),

                      child: const Center(
                        child: Text(
                          'video 6',
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
            
            // texto debajo del video
            SizedBox(height: 8.0,),
           
             Container(
              height: 50,
              width: double.infinity,

              margin: const EdgeInsets.symmetric(
                horizontal: 12.0,
              ),

              color: const Color.fromARGB(255, 251, 251, 251),

              child: Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Expanded(
                    child: Container(
                      color: const Color.fromARGB(255, 243, 93, 33),

                      margin: EdgeInsets.symmetric(
                        horizontal: 2.0,
                      ),

                      child: const Center(
                        child: Text(
                          'texto debajo',
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
                      color: const Color.fromARGB(255, 239, 216, 3),

                      margin: EdgeInsets.symmetric(
                        horizontal: 2.0,
                      ),

                      child: const Center(
                        child: Text(
                          'texto debajo',
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