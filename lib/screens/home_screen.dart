import 'package:flutter/material.dart';
import 'admin_login_screen.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  String? _selectedArea;

  final List<String> _areasTI = [
    'Desarrollo Web',
    'Desarrollo Móvil',
    'Sistemas Operativos',
    'Redes',
    'Computación en la Nube',
    'Metodologías Ágiles',
    'Seguridad Informática',
    'IA y Ciencia de Datos',
    'DevOps',
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _celularController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  void _startEvaluation() {
    if (_formKey.currentState!.validate()) {
      final String nombreCompleto = '${_nombreController.text.trim()} ${_apellidoController.text.trim()}';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatbotScreen(
            nombre: nombreCompleto,
            areaTI: _selectedArea!, apellido: '',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.lock_person_rounded, color: Colors.blueGrey[300]),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminLoginScreen())),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F9F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(Icons.psychology_alt_rounded, size: 70, color: Color(0xFF1F4E4A)),
                  const Text('TalentSelect', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1F4E4A))),
                  const SizedBox(height: 30),

                  _buildTextField(_nombreController, 'Nombre', Icons.person_outline),
                  _buildTextField(_apellidoController, 'Apellido', Icons.person_outline),
                  _buildTextField(_celularController, 'Celular', Icons.phone_android, TextInputType.phone),
                  _buildTextField(_correoController, 'Correo Electrónico', Icons.email_outlined, TextInputType.emailAddress),

                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _selectedArea,
                    decoration: InputDecoration(
                      labelText: 'Área de especialidad',
                      prefixIcon: const Icon(Icons.computer_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _areasTI.map((area) => DropdownMenuItem(value: area, child: Text(area))).toList(),
                    onChanged: (val) => setState(() => _selectedArea = val),
                    validator: (val) => val == null ? 'Por favor selecciona un área' : null,
                  ),
                  const SizedBox(height: 30),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F4E4A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _startEvaluation,
                    child: const Text('Iniciar Proceso', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, [TextInputType type = TextInputType.text]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        maxLength: (type == TextInputType.phone) ? 10 : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: Colors.white,
          counterText: "",
        ),
        validator: (val) {
          if (val == null || val.isEmpty) return 'Este campo es obligatorio';

          if (label == 'Nombre' || label == 'Apellido') {
            if (!RegExp(r'^[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+$').hasMatch(val)) {
              return 'Inicia con mayúscula y sigue con minúsculas';
            }
          }

          if (label == 'Celular') {
            if (!RegExp(r'^[0-9]{10}$').hasMatch(val)) {
              return 'Debe ser de 10 dígitos numéricos';
            }
          }

          if (label == 'Correo Electrónico') {
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
              return 'Ingresa un correo válido (ej: usuario@dominio.com)';
            }
          }
          return null;
        },
      ),
    );
  }
}