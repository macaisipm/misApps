
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../theme/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final correoController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool cargando = false;
  bool mostrarPassword = false;

  // Iniciar sesión con correo y contraseña
  Future<void> iniciarSesionCorreo() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => cargando = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correoController.text.trim(),
        password: passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo iniciar sesión: ${e.code}'),
        ),
      );
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  // Iniciar sesión con Google
  Future<void> iniciarSesionGoogle() async {
    setState(() => cargando = true);

    try {
      final googleUser = await GoogleSignIn.instance.authenticate();

      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (!mounted) return;

      if (e.code != GoogleSignInExceptionCode.canceled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al ingresar con Google: $e')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de Firebase: ${e.code}')),
      );
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bienvenido',
                  style: textos.headlineLarge,
                ),

                const SizedBox(height: AppSpacing.lg24),

                // Correo electrónico
                TextFormField(
                  controller: correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Ingresa tu correo electrónico';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md16),

                // Contraseña
                TextFormField(
                  controller: passwordController,
                  obscureText: !mostrarPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          mostrarPassword = !mostrarPassword;
                        });
                      },
                      icon: Icon(
                        mostrarPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'Ingresa tu contraseña';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.lg24),

                // Ingresar con correo
                FilledButton(
                  onPressed: cargando ? null : iniciarSesionCorreo,
                  child: const Text('Iniciar sesión'),
                ),

                const SizedBox(height: AppSpacing.md16),

                // Ingresar con Google
                OutlinedButton.icon(
                  onPressed: cargando ? null : iniciarSesionGoogle,
                  icon: const Icon(Icons.account_circle_outlined),
                  label: const Text('Continuar con Google'),
                ),

                if (cargando) ...[
                  const SizedBox(height: AppSpacing.md16),
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

