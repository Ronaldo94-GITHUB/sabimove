import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const SabiMoveApp());
}

class SabiMoveApp extends StatelessWidget {
  const SabiMoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SabiMove',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  size: 70,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'SabiMove',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172033),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'by Sabino AI',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Mobilidade inteligente\nem tempo real.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  height: 1.4,
                  color: Color(0xFF5B6475),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MapPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_rounded),
                  label: const Text(
                    'Ver ônibus no mapa',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Rotas • Pontos • Previsões',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7A8495),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    const agudos = LatLng(-22.4694, -48.9875);

    final routePoints = <LatLng>[
      const LatLng(-22.4710, -48.9940),
      const LatLng(-22.4698, -48.9915),
      const LatLng(-22.4694, -48.9875),
      const LatLng(-22.4688, -48.9830),
      const LatLng(-22.4675, -48.9785),
    ];

    final busMarkers = <Marker>[
      Marker(
        point: const LatLng(-22.4708, -48.9930),
        width: 56,
        height: 56,
        child: GestureDetector(
          onTap: () {
            _showBusInfo(
              context,
              line: 'Linha 01',
              direction: 'Centro → Bairro',
              bus: 'Ônibus 101',
              arrival: 'Próxima parada: 3 min',
            );
          },
          child: const _BusMarker(label: '01'),
        ),
      ),
      Marker(
        point: const LatLng(-22.4694, -48.9875),
        width: 56,
        height: 56,
        child: GestureDetector(
          onTap: () {
            _showBusInfo(
              context,
              line: 'Linha 01',
              direction: 'Bairro → Centro',
              bus: 'Ônibus 102',
              arrival: 'Próxima parada: 5 min',
            );
          },
          child: const _BusMarker(label: '02'),
        ),
      ),
      Marker(
        point: const LatLng(-22.4680, -48.9810),
        width: 56,
        height: 56,
        child: GestureDetector(
          onTap: () {
            _showBusInfo(
              context,
              line: 'Linha 02',
              direction: 'Centro → Zona Leste',
              bus: 'Ônibus 201',
              arrival: 'Próxima parada: 7 min',
            );
          },
          child: const _BusMarker(label: '03'),
        ),
      ),
    ];

    final stopMarkers = <Marker>[
      const Marker(
        point: LatLng(-22.4710, -48.9940),
        width: 34,
        height: 34,
        child: _BusStopMarker(),
      ),
      const Marker(
        point: LatLng(-22.4694, -48.9875),
        width: 34,
        height: 34,
        child: _BusStopMarker(),
      ),
      const Marker(
        point: LatLng(-22.4675, -48.9785),
        width: 34,
        height: 34,
        child: _BusStopMarker(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mapa SabiMove',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Informações',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AlertDialog(
                  title: Text('SabiMove'),
                  content: Text(
                    'Os ônibus, pontos e horários desta versão são simulados para desenvolvimento.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: agudos,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.com.sabinoai.sabimove',
              ),

              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 6,
                    color: Colors.blue,
                  ),
                ],
              ),

              MarkerLayer(
                markers: [
                  ...stopMarkers,
                  ...busMarkers,
                ],
              ),
            ],
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.route_rounded,
                      color: Color(0xFF1565C0),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Linha demonstrativa',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '3 ônibus • 3 pontos • dados simulados',
                            style: TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Ativa',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBusInfo(
    BuildContext context, {
    required String line,
    required String direction,
    required String bus,
    required String arrival,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(bus),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _InfoRow(
                icon: Icons.compare_arrows_rounded,
                text: direction,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.schedule_rounded,
                text: arrival,
              ),
              const SizedBox(height: 12),
              const _InfoRow(
                icon: Icons.check_circle_outline,
                text: 'Status: Em operação',
              ),
              const SizedBox(height: 18),
              const Text(
                'Dados simulados para desenvolvimento.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BusMarker extends StatelessWidget {
  final String label;

  const _BusMarker({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black26,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.directions_bus_rounded,
            color: Colors.white,
            size: 30,
          ),
          Positioned(
            bottom: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusStopMarker extends StatelessWidget {
  const _BusStopMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.deepOrange,
          width: 3,
        ),
      ),
      child: const Icon(
        Icons.location_on,
        color: Colors.deepOrange,
        size: 20,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 22,
          color: const Color(0xFF1565C0),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}