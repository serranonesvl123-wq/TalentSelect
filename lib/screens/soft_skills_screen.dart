import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // <--- AGREGAR ESTO
import 'results_screen.dart';
import 'package:talentselect/api_keys.dart';

class SoftSkillsScreen extends StatefulWidget {
  final String nombre;
  final String apellido;
  final String areaTI;
  final int puntajeTecnico;

  const SoftSkillsScreen({
    super.key,
    required this.nombre,
    required this.apellido,
    required this.areaTI,
    required this.puntajeTecnico,
  });

  @override
  State<SoftSkillsScreen> createState() => _SoftSkillsScreenState();
}

class _SoftSkillsScreenState extends State<SoftSkillsScreen> with WidgetsBindingObserver {
  List<dynamic> _preguntasSoftIA = [];
  int _preguntaActualIndex = 0;
  int _puntajeSoftAcumulado = 0;
  bool _cargandoIA = true;

  // Variables para el control del cronómetro por pregunta
  Timer? _countdownTimer;
  int _tiempoRestante = 30; // Límite de 30 segundos por pregunta
  final int _tiempoMaximo = 30;

  // Variables para el control anti-trampas
  int _advertenciasTrampa = 0;
  final int _maxAdvertencias = 3;

  // Paleta de colores institucional
  final Color tealColor = const Color(0xFF1F4E4A);
  final Color accentColor = const Color(0xFF40E0D0);
  final Color blackColor = const Color(0xFF121212);
  final Color warningColor = const Color(0xFFD32F2F);

  // Banco de dilemas humanos y situaciones de equipo por cada área de TI
  final Map<String, List<String>> _situacionesPorArea = {
    'Desarrollo Web': [
      'Desacuerdos intensos en la arquitectura frontend vs backend durante la planificación',
      'Lidiar con cambios drásticos de alcance y requerimientos de último minuto por el cliente',
      'Mantener comunicación asertiva durante revisiones de código conflictivas en Pull Requests',
      'Manejo de estrés colectivo ante caídas de servidor o bugs críticos en producción',
      'Colaboración interdepartamental tensa con diseñadores UI/UX y Product Owners'
    ],
    'Desarrollo Móvil': [
      'Negociación de tiempos de entrega tras el rechazo imprevisto de la app en la App Store/Play Store',
      'Priorización en equipo al resolver bugs de producción vs avanzar con nuevas características',
      'Gestión de frustración al probar el rendimiento en múltiples dispositivos físicos y emuladores lentos',
      'Liderazgo y alineación cuando hay fricciones entre los desarrolladores iOS y Android',
      'Explicación empática de limitaciones técnicas de hardware a stakeholders y gerentes comerciales'
    ],
    'Sistemas Operativos': [
      'Resolución de conflictos de liderazgo al diagnosticar caídas masivas de servidores',
      'Documentación clara, honesta y transparente de incidentes graves de seguridad',
      'Toma de decisiones rápidas bajo presión extrema durante fallas críticas del sistema de archivos',
      'Colaboración y mediación con equipos de desarrollo que demandan excesivos recursos de infraestructura',
      'Mentoría paciente y asertiva a administradores de sistemas juniors ante scripting defectuoso'
    ],
    'Redes': [
      'Coordinación y diplomacia al negociar ventanas de mantenimiento nocturno con áreas críticas del negocio',
      'Explicación didáctica y sin tecnicismos de vulnerabilidades de red a directores financieros',
      'Manejo de la comunicación y calma del equipo durante un ataque activo de denegación de servicio (DDoS)',
      'Resolución de fricciones con proveedores externos de telecomunicaciones ante retrasos de servicio',
      'Colaboración estrecha con ciberseguridad al aplicar políticas restrictivas que molestan a los usuarios'
    ],
    'Computación en la Nube': [
      'Negociación y justificación técnica de incrementos de costos de nube con gerencia reacia',
      'Soporte mutuo y paciencia grupal al migrar bases de datos heredadas complejas a entornos cloud',
      'Establecimiento de responsabilidades compartidas de seguridad sin generar debates defensivos',
      'Liderazgo asertivo al coordinar simulacros de recuperación ante desastres con el equipo',
      'Paciencia y alineación con desarrollo ante picos masivos de consumo de recursos web'
    ],
    'Metodologías Ágiles': [
      'Resolución de fricciones personales o culpas cruzadas entre desarrolladores durante la Retrospectiva',
      'Negociación constructiva con Product Owners que presionan para meter más tareas al Sprint en curso',
      'Incentivación del auto-organización en equipos desmotivados o acostumbrados al micromanagement',
      'Facilitación empática de Daily Standups donde los miembros tienden a monopolizar el tiempo',
      'Manejo constructivo de la frustración colectiva cuando el equipo no logra cumplir el Sprint Goal'
    ],
    'Seguridad Informática': [
      'Concientización y paciencia al capacitar a empleados propensos a caer en campañas de Phishing',
      'Manejo asertivo de quejas de desarrolladores molestos por los bloqueos de código de las auditorías de seguridad',
      'Liderazgo y calma al coordinar la respuesta inmediata ante una sospecha de filtración de datos',
      'Presentación objetiva de riesgos críticos a directores sin caer en el alarmismo o lenguaje complejo',
      'Negociación y tacto ético con el equipo de TI al realizar pruebas controladas de ingeniería social'
    ],
    'IA y Ciencia de Datos': [
      'Explicación comprensible y honesta del comportamiento de modelos de "caja negra" a clientes de negocios',
      'Colaboración asertiva con ingenieros de datos ante discrepancias en la calidad u origen de la información',
      'Gestión realista de expectativas frente a directivos que esperan resultados de IA milagrosos e inmediatos',
      'Debates éticos en el equipo sobre posibles sesgos en los sets de datos de entrenamiento',
      'Mantener la resiliencia y motivación del equipo en fases prolongadas de ajuste de hiperparámetros'
    ],
    'DevOps': [
      'Fomento de la empatía mutua y romper barreras históricas entre programadores y operaciones',
      'Manejo del temperamento y frustración colectiva cuando falla un pipeline de CI/CD en un despliegue urgente',
      'Facilitación de autopsias sin culpables (Blameless Post-Mortems) tras caídas críticas de producción',
      'Negociación con oficiales de seguridad (DevSecOps) para automatizar validaciones sin entorpecer los sprints',
      'Mentoría motivadora a equipos tradicionales de operaciones que temen ser reemplazados por la automatización'
    ]
  };

  @override
  void initState() {
    super.initState();
    // Registramos el observador para detectar cuando el usuario intente hacer trampa o salir de la app
    WidgetsBinding.instance.addObserver(this);
    _generarHabilidadesBlandasConIA();
  }

  @override
  void dispose() {
    // Liberamos los observadores y timers activos para evitar fugas de memoria
    WidgetsBinding.instance.removeObserver(this);
    _detenerCronometro();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Si la app pierde el foco (se minimiza, abren otra app o bajan la barra de tareas)
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _detenerCronometro();
      _registrarAdvertenciaTrampa();
    } else if (state == AppLifecycleState.resumed) {
      // Al regresar a la app, si no ha sido penalizado permanentemente, reiniciamos el cronómetro
      if (_advertenciasTrampa < _maxAdvertencias && !_cargandoIA) {
        _iniciarCronometro();
      }
    }
  }

  void _registrarAdvertenciaTrampa() {
    FirebaseDatabase.instance.ref().child('alertas').push().set({
      'nombre': widget.nombre,
      'apellido': widget.apellido,
      'mensaje': 'Intento de copia: Salida de la pantalla de evaluación',
      'fecha': DateTime.now().toString(),
    });

    setState(() {
      _advertenciasTrampa++;
    });

    if (_advertenciasTrampa >= _maxAdvertencias) {
      _detenerCronometro();
      _forzarFinalizacionPorTrampa();
    } else {
      // Diálogo de advertencia emergente
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: warningColor, size: 50),
          title: const Text('¡ADVERTENCIA DE SEGURIDAD!', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            'Has salido o minimizado la pantalla de evaluación.\n\n'
                'Esto se registra como posible intento de copia.\n'
                'Llevas $_advertenciasTrampa/$_maxAdvertencias advertencias. Al llegar a $_maxAdvertencias, tu prueba se cancelará automáticamente.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _iniciarCronometro();
              },
              child: const Text('Entendido y Continuar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void _forzarFinalizacionPorTrampa() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.gavel_rounded, color: warningColor, size: 50),
        title: const Text('EVALUACIÓN ANULADA', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Se ha excedido el límite de advertencias por salir de la aplicación.\n\n'
              'Tu prueba psicométrica de Soft Skills ha sido anulada y se guardará la puntuación acumulada actual.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: warningColor),
            onPressed: () {
              Navigator.of(context).pop();
              _navegarASiguienteFase();
            },
            child: const Text('Proceder a Resultados', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _iniciarCronometro() {
    _detenerCronometro(); // Limpiamos cualquier timer activo
    setState(() {
      _tiempoRestante = _tiempoMaximo;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_tiempoRestante > 0) {
        setState(() {
          _tiempoRestante--;
        });
      } else {
        _detenerCronometro();
        _manejarTiempoAgotado();
      }
    });
  }

  void _detenerCronometro() {
    _countdownTimer?.cancel();
  }

  void _manejarTiempoAgotado() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('¡Tiempo agotado en esta situación! (0 puntos)'),
        backgroundColor: warningColor,
        duration: const Duration(seconds: 2),
      ),
    );
    _procesarRespuesta(0);
  }

  Future<void> _generarHabilidadesBlandasConIA() async {
    setState(() => _cargandoIA = true);

    const apiKey = ApiKeys.groqKey;
    final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");

    final int randomSeed = DateTime.now().millisecondsSinceEpoch;

    final List<String> fallbackList = [
      'Empatía y escucha activa ante desacuerdos en el equipo',
      'Resolución asertiva de conflictos técnicos en proyectos complejos',
      'Manejo constructivo del estrés ante entregas apretadas',
      'Liderazgo situacional y apoyo a compañeros juniors',
      'Adaptabilidad al cambio cuando se redefine una tecnología'
    ];

    final List<String> situacionesDisponibles = List<String>.from(_situacionesPorArea[widget.areaTI] ?? fallbackList);
    situacionesDisponibles.shuffle(Random(randomSeed));
    final String situacionesElegidas = situacionesDisponibles.take(3).join(', ');

    final prompt = """
    Eres un psicólogo organizacional y reclutador TI senior. Tu única tarea es generar un cuestionario psicométrico situacional dinámico, totalmente exclusivo y variado que contenga EXACTAMENTE 10 preguntas situacionales de opción múltiple para evaluar habilidades blandas en el área de: '${widget.areaTI}'.
    
    ID DE SESIÓN ÚNICO: $randomSeed
    CANDIDATO ASOCIADO: ${widget.nombre} ${widget.apellido}

    INSTRUCCIÓN DE EVOLUCIÓN Y CAMBIO CRÍTICO:
    Para esta evaluación psicométrica en específico, es OBLIGATORIO que enfoques las preguntas ÚNICAMENTE en plantear dilemas realistas inspirados en las siguientes 3 situaciones de TI:
    $situacionesElegidas

    Crea historias breves situacionales donde el candidato deba decidir cómo reaccionar. Evita plantillas repetidas.

    REGLAS ESTRICTAS:
    1. Deben ser exactamente 10 reactivos de opción múltiple. Ni más, ni menos.
    2. Cada pregunta debe tener una lista de "opciones" con exactamente 4 alternativas.
    3. Cada opción debe tener un campo "texto" y un campo "puntos" (valores numéricos estrictos: 10 para la respuesta ideal, 6 para una buena, 3 para una regular y 0 para una mala práctica o comportamiento inapropiado).
    4. Devuelve ÚNICAMENTE el arreglo JSON crudo en la raíz. No metas explicaciones, saludos ni formato Markdown de tipo ```json.

    Formato requerido:
    [
      {
        "pregunta": "Texto de la situación...",
        "opciones": [
          {"texto": "Opción ideal", "puntos": 10},
          {"texto": "Opción aceptable", "puntos": 6},
          {"texto": "Opción regular", "puntos": 3},
          {"texto": "Opción incorrecta", "puntos": 0}
        ]
      }
    ]
    """;

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [{"role": "user", "content": prompt}],
          "temperature": 0.95,
          "seed": randomSeed % 2147483647,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String textResponse = jsonResponse['choices'][0]['message']['content'].toString().trim();

        if (textResponse.contains("```")) {
          textResponse = textResponse.split("```")[1];
          if (textResponse.startsWith("json")) {
            textResponse = textResponse.substring(4).trim();
          }
        }

        final dynamic decodedData = jsonDecode(textResponse);
        List<dynamic> preguntasObtenidas = [];

        if (decodedData is List) {
          preguntasObtenidas = decodedData;
        } else if (decodedData is Map) {
          preguntasObtenidas = decodedData.values.firstWhere(
                  (element) => element is List,
              orElse: () => []
          );
        }

        // Mezclamos aleatoriamente las opciones de cada pregunta antes de actualizar el estado
        final random = Random();
        List<dynamic> preguntasShuffled = [];
        for (var p in preguntasObtenidas) {
          if (p is Map) {
            final Map<String, dynamic> preguntaMap = Map<String, dynamic>.from(p);
            if (preguntaMap['opciones'] is List) {
              final List<dynamic> optionsList = List<dynamic>.from(preguntaMap['opciones']);
              optionsList.shuffle(random);
              preguntaMap['opciones'] = optionsList;
            }
            preguntasShuffled.add(preguntaMap);
          } else {
            preguntasShuffled.add(p);
          }
        }

        setState(() {
          _preguntasSoftIA = preguntasShuffled;
          _cargandoIA = false;
        });

        // Iniciamos el cronómetro de la primera pregunta al terminar la carga
        _iniciarCronometro();
      } else {
        throw Exception("Error Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("🚨 ERROR EN SOFT SKILLS GENERATION: $e");

      setState(() {
        _preguntasSoftIA = [
          {
            "pregunta": "Hubo un problema al conectar con el servicio de Soft Skills. ¿Deseas intentar de nuevo?",
            "opciones": [
              {"texto": "Reintentar conexión", "puntos": -1}
            ]
          }
        ];
        _cargandoIA = false;
      });
    }
  }

  void _procesarRespuesta(int points) {
    _detenerCronometro();

    if (points == -1) {
      _generarHabilidadesBlandasConIA();
      return;
    }

    _puntajeSoftAcumulado += points;

    if (_preguntaActualIndex + 1 < _preguntasSoftIA.length) {
      setState(() {
        _preguntaActualIndex++;
      });
      _iniciarCronometro(); // Iniciamos el cronómetro para el nuevo reactivo
    } else {
      _navegarASiguienteFase();
    }
  }

  void _navegarASiguienteFase() {
    _detenerCronometro();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          nombre: widget.nombre,
          apellido: widget.apellido,
          areaTI: widget.areaTI,
          puntajeTecnico: widget.puntajeTecnico,
          puntajeSoftSkills: _puntajeSoftAcumulado,
        ),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoIA) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F9F9),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: tealColor),
              const SizedBox(height: 24),
              Text(
                'PREPARANDO EVALUACIÓN SENSORIAL / SOFT SKILLS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: tealColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final reactivoActual = _preguntasSoftIA[_preguntaActualIndex];
    final List<dynamic> opciones = reactivoActual['opciones'] is List ? reactivoActual['opciones'] : [];

    // PopScope inactiva por completo el retroceso físico para mantener la seguridad
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Atención! No puedes salir de la evaluación activa.'),
            backgroundColor: warningColor,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9F9),
        appBar: AppBar(
          title: const Text('FASE II: HABILIDADES BLANDAS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          automaticallyImplyLeading: false,
          backgroundColor: tealColor,
          foregroundColor: Colors.white,
          actions: [
            // Indicador de advertencias de trampa en el AppBar
            if (_advertenciasTrampa > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Chip(
                  avatar: const Icon(Icons.warning, color: Colors.white, size: 16),
                  backgroundColor: warningColor,
                  label: Text(
                    '$_advertenciasTrampa/$_maxAdvertencias',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  '${_preguntaActualIndex + 1} / ${_preguntasSoftIA.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra de progreso del cuestionario
              LinearProgressIndicator(
                value: _preguntasSoftIA.isNotEmpty ? (_preguntaActualIndex + 1) / _preguntasSoftIA.length : 0,
                backgroundColor: Colors.black12,
                color: accentColor,
                minHeight: 4,
              ),
              const SizedBox(height: 16),

              // Barra visual del cronómetro secundario
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tiempo restante:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[600], fontSize: 13),
                      ),
                      Text(
                        '$_tiempoRestante s',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _tiempoRestante <= 10 ? warningColor : tealColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _tiempoRestante / _tiempoMaximo,
                      backgroundColor: Colors.black12,
                      color: _tiempoRestante <= 10 ? warningColor : accentColor,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Text(
                'CANDIDATO: ${widget.nombre.toUpperCase()} ${widget.apellido.toUpperCase()}',
                style: TextStyle(color: tealColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Text(
                  reactivoActual['pregunta'] ?? '',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: blackColor, height: 1.4),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  itemCount: opciones.length,
                  itemBuilder: (context, index) {
                    final Map<String, dynamic> opcion = Map<String, dynamic>.from(opciones[index] ?? {});
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: blackColor,
                          side: const BorderSide(color: Colors.black12),
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.centerLeft,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _procesarRespuesta(opcion['puntos'] ?? 0),
                        child: Text(
                          opcion['texto'] ?? '',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}