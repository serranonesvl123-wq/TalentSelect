import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart'; // Importación de Firebase Core
import 'screens/home_screen.dart';

void main() async {
  // Asegura que los bindings nativos de Flutter (y Kotlin) estén listos
  WidgetPreviewBinding: WidgetsFlutterBinding.ensureInitialized();

  // Inicialización asíncrona de Firebase antes de arrancar la UI
  await Firebase.initializeApp();

  // Bloquear orientación vertical para mantener una UX corporativa consistente
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const TalentSelectApp());
}

class TalentSelectApp extends StatelessWidget {
  const TalentSelectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TalentSelect',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF40E0D0), // Turquesa Base
          primary: const Color(0xFF40E0D0),   // Verde agua
          secondary: const Color(0xFF7FFFD4), // Aquamarina pastel
          background: const Color(0xFFF5F9F9), // Fondo institucional limpio
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F4E4A),
            letterSpacing: 1.2,
          ),
        ),
      ),
      // La aplicación arranca conectando directamente con la interfaz principal de registro
      home: const HomeScreen(),
    );
  }
}