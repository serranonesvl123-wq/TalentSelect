import 'dart:convert';
import 'dart:async';
import 'dart:math'; // ¡Agregado de vuelta para garantizar el correcto funcionamiento de Random()!
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // <--- AGREGAR ESTO
import 'soft_skills_screen.dart';
import 'package:talentselect/api_keys.dart';

class ChatbotScreen extends StatefulWidget {
  final String nombre;
  final String apellido;
  final String areaTI;

  const ChatbotScreen({
    super.key,
    required this.nombre,
    required this.apellido,
    required this.areaTI,
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with WidgetsBindingObserver {
  List<dynamic> _preguntasIA = [];
  int _preguntaActualIndex = 0;
  int _puntajeTecnicoAcumulado = 0;
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

  @override
  void initState() {
    super.initState();
    // Registramos el observador para detectar cuando el usuario sale de la app
    WidgetsBinding.instance.addObserver(this);
    _generarBancoPreguntasConIA();
  }

  @override
  void dispose() {
    // Liberamos los observadores y timers para evitar fugas de memoria
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
      // Mostramos un diálogo persistente advirtiendo al usuario
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
              'Tu prueba técnica ha sido terminada inmediatamente y se guardará la puntuación acumulada actual.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: warningColor),
            onPressed: () {
              Navigator.of(context).pop();
              _navegarASiguienteFase();
            },
            child: const Text('Proceder a Soft Skills', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _iniciarCronometro() {
    _detenerCronometro(); // Limpiamos cualquier timer previo activo
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
    // Al agotarse el tiempo, mostramos un aviso rápido en pantalla y pasamos con 0 puntos
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('¡Tiempo agotado en esta pregunta! (0 puntos)'),
        backgroundColor: warningColor,
        duration: const Duration(seconds: 2),
      ),
    );
    _procesarRespuesta(0);
  }

  Future<void> _generarBancoPreguntasConIA() async {
    const apiKey = ApiKeys.groqKey;
    final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");
    final int randomSeed = DateTime.now().millisecondsSinceEpoch;

    final prompt = """
    Eres un reclutador técnico senior de TI. Tu única tarea es generar un examen técnico dinámico, exclusivo y variado que contenga EXACTAMENTE 10 preguntas técnicas distintas de opción múltiple, de nivel estándar/intermedio, para evaluar a un candidato en el área de: '${widget.areaTI}'.
    
    INSTRUCCIÓN DE ALEATORIEDAD (ID de sesión única: $randomSeed):
    Para asegurar que cada evaluación sea totalmente diferente a las anteriores y evitar que se repitan las mismas preguntas, debes rotar de forma aleatoria entre diversos subtemas de '${widget.areaTI}' (por ejemplo: sintaxis, teoría, patrones de diseño, depuración, rendimiento o escenarios reales de resolución de problemas), cambiando radicalmente las preguntas en cada ejecución.
    
    REGLAS ESTRICTAS:
    1. Deben ser exactamente 10 reactivos. Ni más, ni menos.
    2. Cada pregunta debe tener una lista de "opciones" con exactamente 4 alternativas.
    3. Cada opción debe tener un campo "texto" y un campo "puntos" (la mejor opción vale 10 puntos, una aceptable 6, una regular 3 y una mala 0).
    4. Devuelve ÚNICAMENTE el arreglo JSON crudo en la raíz. No incluyas explicaciones, saludos ni formato Markdown de tipo ```json.

    Estructura requerida:
    [
      {
        "pregunta": "Texto de la pregunta...",
        "opciones": [
          {"texto": "Respuesta ideal", "puntos": 10},
          {"texto": "Respuesta aceptable", "puntos": 6},
          {"texto": "Respuesta regular", "puntos": 3},
          {"texto": "Respuesta incorrecta", "puntos": 0}
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
          "messages": [
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.95,
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
          _preguntasIA = preguntasShuffled;
          _cargandoIA = false;
        });

        // Iniciamos el cronómetro para la primera pregunta
        _iniciarCronometro();
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() {
        _preguntasIA = [
          {
            "pregunta": "Error de comunicación con el servicio de IA. ¿Deseas reintentar prueba?",
            "opciones": [
              {"texto": "Reintentar prueba", "puntos": 10},
              {"texto": "Salir", "puntos": 0}
            ]
          }
        ];
        _cargandoIA = false;
      });
    }
  }

  void _procesarRespuesta(int puntos) {
    _detenerCronometro();
    _puntajeTecnicoAcumulado += puntos;

    if (_preguntaActualIndex + 1 < _preguntasIA.length) {
      setState(() {
        _preguntaActualIndex++;
      });
      _iniciarCronometro(); // Reiniciamos el tiempo para la siguiente pregunta
    } else {
      _navegarASiguienteFase();
    }
  }

  void _navegarASiguienteFase() {
    _detenerCronometro();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SoftSkillsScreen(
          nombre: widget.nombre,
          apellido: widget.apellido,
          areaTI: widget.areaTI,
          puntajeTecnico: _puntajeTecnicoAcumulado,
        ),
      ),
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
                'PREPARANDO EVALUACIÓN TÉCNICA SECURE-FLOW',
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

    final reactivoActual = _preguntasIA[_preguntaActualIndex];
    final List<dynamic> opciones = reactivoActual['opciones'] is List
        ? reactivoActual['opciones']
        : [];

    // PopScope envuelve toda la UI para inhabilitar retroceso por gestos o botones
    return PopScope(
      canPop: false, // Bloquea la acción de retroceso
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Alerta rápida al intentar salirse con gestos físicos
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
          title: const Text('FASE I: PRUEBA TÉCNICA', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          automaticallyImplyLeading: false,
          backgroundColor: tealColor,
          foregroundColor: Colors.white,
          actions: [
            // Indicador visual de advertencias por intento de trampa
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
                  '${_preguntaActualIndex + 1} / ${_preguntasIA.length}',
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
              // Barra de progreso general del examen
              LinearProgressIndicator(
                value: _preguntasIA.isNotEmpty ? (_preguntaActualIndex + 1) / _preguntasIA.length : 0,
                backgroundColor: Colors.black12,
                color: accentColor,
                minHeight: 4,
              ),
              const SizedBox(height: 16),

              // Barra del cronómetro de la pregunta actual (Verde -> Amarillo -> Rojo según el tiempo)
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