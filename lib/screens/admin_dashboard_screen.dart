import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final Query _candidatosQuery = FirebaseDatabase.instance.ref().child('candidatos');
  String _areaSeleccionada = 'Todos';

  // Paleta de colores oficial unificada
  final Color tealColor = const Color(0xFF1F4E4A);
  final Color accentColor = const Color(0xFF40E0D0);
  final Color lightBgColor = const Color(0xFFF5F9F9);
  final Color blackColor = const Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Panel de Reclutamiento TIC',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tealColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: tealColor),
            tooltip: 'Cerrar Sesión',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder(
        stream: _candidatosQuery.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: tealColor));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final dataSnapshot = snapshot.data?.snapshot;

          if (dataSnapshot == null || dataSnapshot.value == null) {
            return _buildEmptyState();
          }

          final Map<dynamic, dynamic> map = dataSnapshot.value as Map<dynamic, dynamic>;
          final List<Map<dynamic, dynamic>> listaCompleta = [];

          map.forEach((key, value) {
            if (value is Map) {
              listaCompleta.add(Map<dynamic, dynamic>.from(value));
            }
          });

          // Listado de áreas para filtrado
          final List<String> listaAreas = [
            'Todos',
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

          List<Map<dynamic, dynamic>> candidatosFiltrados = [];
          if (_areaSeleccionada == 'Todos') {
            candidatosFiltrados = List.from(listaCompleta);
          } else {
            candidatosFiltrados = listaCompleta
                .where((c) => c['areaEvaluada'].toString() == _areaSeleccionada)
                .toList();
          }

          // Clasificación de mayor a menor puntaje
          candidatosFiltrados.sort((a, b) {
            final int scoreA = (a['puntajeTecnico'] ?? 0) + (a['puntajeSoftSkills'] ?? 0);
            final int scoreB = (b['puntajeTecnico'] ?? 0) + (b['puntajeSoftSkills'] ?? 0);
            return scoreB.compareTo(scoreA);
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCategorySelector(listaAreas),
              Expanded(
                child: candidatosFiltrados.isEmpty
                    ? _buildEmptyStateFiltered()
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  itemCount: candidatosFiltrados.length,
                  itemBuilder: (context, index) {
                    final candidato = candidatosFiltrados[index];
                    return _buildCandidateCard(candidato, index + 1);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategorySelector(List<String> areas) {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        itemCount: areas.length,
        itemBuilder: (context, index) {
          final area = areas[index];
          final isSelected = area == _areaSeleccionada;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                area,
                style: TextStyle(
                  color: isSelected ? Colors.white : tealColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              selectedColor: tealColor,
              backgroundColor: lightBgColor,
              elevation: 0,
              pressElevation: 0,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : tealColor.withOpacity(0.15),
                ),
              ),
              onSelected: (bool selected) {
                if (selected) {
                  setState(() {
                    _areaSeleccionada = area;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCandidateCard(Map<dynamic, dynamic> candidato, int ranking) {
    final int pt = candidato['puntajeTecnico'] ?? 0;
    final int ps = candidato['puntajeSoftSkills'] ?? 0;
    final int total = pt + ps;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: tealColor,
          collapsedIconColor: Colors.blueGrey[400],
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$ranking',
                style: TextStyle(color: tealColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          title: Text(
            '${candidato['nombre'] ?? 'Sin'} ${candidato['apellido'] ?? 'Nombre'}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: blackColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${candidato['areaEvaluada'] ?? 'TI'}  •  $total / 200 pts',
            style: TextStyle(
              color: Colors.blueGrey[400],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 16),

                  // Desglose de puntuaciones en bloque vertical para evitar errores de desbordamiento horizontal
                  _buildMetricVerticalBlock(
                      'Evaluación Técnica',
                      '$pt / 100',
                      Icons.code_rounded,
                      Colors.indigo
                  ),
                  const SizedBox(height: 12),
                  _buildMetricVerticalBlock(
                      'Habilidades Blandas',
                      '$ps / 100',
                      Icons.psychology_rounded,
                      tealColor
                  ),
                  const SizedBox(height: 20),

                  _buildDetailedSection(
                    'Análisis Soft Skills',
                    candidato['diagnosticoBlando'] ?? 'Sin diagnóstico registrado.',
                    Icons.chat_bubble_outline_rounded,
                    tealColor,
                  ),
                  const SizedBox(height: 16),

                  _buildDetailedSection(
                    'Fortalezas Técnicas',
                    candidato['fortalezaTecnica'] ?? 'Sin fortalezas registradas.',
                    Icons.sentiment_satisfied_alt_rounded,
                    accentColor,
                  ),
                  const SizedBox(height: 16),

                  _buildDetailedSection(
                    'Estrategias de Mejora',
                    candidato['mejoraTecnica'] ?? 'Sin recomendaciones registradas.',
                    Icons.trending_up_rounded,
                    Colors.orange,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMetricVerticalBlock(String label, String score, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.blueGrey[500],
                    fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Text(
              score,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: blackColor
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedSection(String title, String content, IconData icon, Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: themeColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: tealColor, letterSpacing: 0.3),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: lightBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            content,
            style: TextStyle(fontSize: 12, color: blackColor.withOpacity(0.85), height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 48, color: tealColor.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            'No hay aspirantes registrados todavía.',
            style: TextStyle(color: Colors.blueGrey[400], fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateFiltered() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: tealColor.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            'No hay candidatos en esta área.',
            style: TextStyle(color: Colors.blueGrey[400], fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}