import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ResultsScreen extends StatefulWidget {
  final String nombre;
  final String apellido;
  final String areaTI;
  final int puntajeTecnico;
  final int puntajeSoftSkills;

  const ResultsScreen({
    super.key,
    required this.nombre,
    required this.apellido,
    required this.areaTI,
    required this.puntajeTecnico,
    required this.puntajeSoftSkills,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  bool _guardandoEnFirebase = true;
  String _mensajeFirebase = 'Procesando y guardando tu expediente...';

  late String _fortalezaTecnica;
  late String _mejoraTecnica;
  late String _diagnosticoBlando;

  // Paleta de colores verde agua/teal institucional adaptada al proyecto
  final Color tealColor = const Color(0xFF1F4E4A);
  final Color accentColor = const Color(0xFF40E0D0);
  final Color blackColor = const Color(0xFF121212);

  @override
  void initState() {
    super.initState();
    _calcularDiagnostico();
    _subirResultadosAFirebase();
  }

  void _calcularDiagnostico() {
    final int pt = widget.puntajeTecnico;
    final int ps = widget.puntajeSoftSkills;

    // --- 1. DIAGNÓSTICO TÉCNICO POR RANGOS DE PUNTAJE (0-100) ---
    if (pt >= 0 && pt <= 30) {
      _fortalezaTecnica = 'Demuestras nociones iniciales de la tecnología y una actitud receptiva para incorporar conocimientos estructurados.';
      _mejoraTecnica = 'Es altamente recomendable priorizar el estudio de las bases teóricas, sintaxis fundamental y conceptos esenciales en el área de ${widget.areaTI}.';
    } else if (pt >= 31 && pt <= 50) {
      _fortalezaTecnica = 'Comprensión elemental de las herramientas del área. Eres capaz de resolver tareas guiadas y asimilar problemas sencillos.';
      _mejoraTecnica = 'Se sugiere realizar ejercicios prácticos que fortalezcan tu lógica aplicada, y profundizar en las bases fundamentales de ${widget.areaTI}.';
    } else if (pt >= 51 && pt <= 70) {
      _fortalezaTecnica = 'Sólido dominio de conceptos operativos y de nivel intermedio. Consigues solucionar problemas de forma autónoma bajo estándares comunes.';
      _mejoraTecnica = 'Para dar el salto al siguiente nivel, te beneficiaría explorar temas de optimización de rendimiento, arquitectura de software y metodologías avanzadas.';
    } else if (pt >= 71 && pt <= 85) {
      _fortalezaTecnica = 'Excelente nivel técnico. Tienes la habilidad para estructurar soluciones limpias, eficientes y bien organizadas en ${widget.areaTI}.';
      _mejoraTecnica = 'Puedes enfocar tus esfuerzos en el estudio de patrones de diseño complejos, escalabilidad de sistemas e integración de tecnologías de vanguardia.';
    } else { // 86 a 100 puntos
      _fortalezaTecnica = 'Nivel técnico sobresaliente y altamente competitivo. Gran capacidad de abstracción, resolución algorítmica compleja y eficiencia técnica notable.';
      _mejoraTecnica = 'Para continuar con tu crecimiento, se recomienda enfocarte en liderar iniciativas de arquitectura de software, mentoría de talentos juniors o contribución a proyectos Open Source.';
    }

    // --- 2. DIAGNÓSTICO DE HABILIDADES BLANDAS (0-100) ---
    if (ps >= 0 && ps <= 30) {
      _diagnosticoBlando = 'En desarrollo (${ps}/100 pts). Presentas un amplio margen para potenciar la comunicación asertiva, el manejo de la frustración colectiva y el trabajo integrado ante desafíos técnicos.';
    } else if (ps >= 31 && ps <= 50) {
      _diagnosticoBlando = 'Básico (${ps}/100 pts). Cuentas con nociones iniciales de colaboración, pero se sugiere reforzar la escucha activa, la empatía grupal y la resolución pacífica de desacuerdos cotidianos.';
    } else if (ps >= 51 && ps <= 70) {
      _diagnosticoBlando = 'Competente (${ps}/100 pts). Demuestras bases estables y funcionales de interacción. Te adaptas con facilidad a los equipos de trabajo y aportas de manera constructiva a las metas grupales.';
    } else if (ps >= 71 && ps <= 85) {
      _diagnosticoBlando = 'Destacado (${ps}/100 pts). Muestras una alta madurez emocional, asertividad continua ante la presión y una excelente capacidad para mediar y resolver diferencias en el equipo de TI.';
    } else { // 86 a 100 puntos
      _diagnosticoBlando = 'Sobresaliente (${ps}/100 pts). Liderazgo situacional impecable y un alto sentido ético. Facilitas la integración colaborativa de manera natural y sobresales en la resolución de dilemas organizacionales complejos.';
    }
  }

  Future<void> _subirResultadosAFirebase() async {
    try {
      final String timestampId = DateTime.now().millisecondsSinceEpoch.toString();
      await _dbRef.child('candidatos').child(timestampId).set({
        'nombre': widget.nombre,
        'apellido': widget.apellido,
        'areaEvaluada': widget.areaTI,
        'puntajeTecnico': widget.puntajeTecnico,
        'puntajeSoftSkills': widget.puntajeSoftSkills,
        'diagnosticoBlando': _diagnosticoBlando,
        'fortalezaTecnica': _fortalezaTecnica,
        'mejoraTecnica': _mejoraTecnica,
        'fechaRegistro': DateTime.now().toIso8601String(),
      });
      setState(() => _guardandoEnFirebase = false);
    } catch (e) {
      setState(() {
        _guardandoEnFirebase = false;
        _mensajeFirebase = 'Error al sincronizar: $e';
      });
    }
  }

  Widget _buildResultCard(String title, String content, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: tealColor,
                  ),
                )
              ],
            ),
            const Divider(height: 24, thickness: 1),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: blackColor.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F9),
      appBar: AppBar(
        title: const Text('Diagnóstico Final', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: tealColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _guardandoEnFirebase
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: tealColor),
            const SizedBox(height: 24),
            Text(
              _mensajeFirebase,
              style: TextStyle(color: tealColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¡Evaluación Concluida, ${widget.nombre} ${widget.apellido}!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: tealColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Área Evaluada: ${widget.areaTI}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blueGrey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Tarjetas informativas de Diagnóstico
            _buildResultCard(
                'Tus Fortalezas Técnicas',
                _fortalezaTecnica,
                Icons.thumb_up_alt_rounded,
                accentColor
            ),
            const SizedBox(height: 16),
            _buildResultCard(
                'Áreas de Mejora Técnica',
                _mejoraTecnica,
                Icons.trending_up_rounded,
                Colors.orangeAccent
            ),
            const SizedBox(height: 16),
            _buildResultCard(
                'Análisis Soft Skills',
                _diagnosticoBlando,
                Icons.psychology_rounded,
                Colors.indigoAccent
            ),
            const SizedBox(height: 40),

            // Botón Finalizar
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: tealColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
              icon: const Icon(Icons.exit_to_app),
              label: const Text(
                'Finalizar y Salir',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}