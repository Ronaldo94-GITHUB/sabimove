import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/mock_lines.dart';
import '../models/transit_line.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  TransitLine selectedLine = mockLines.first;

  @override
  Widget build(BuildContext context) {
    const agudos = LatLng(-22.4694, -48.9875);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mapa SabiMove',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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
                    points: selectedLine.routePoints,
                    strokeWidth: 6,
                    color: Colors.blue,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  ...selectedLine.stops.map(
                    (stop) => Marker(
                      point: stop,
                      width: 36,
                      height: 36,
                      child: Container(
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
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                  Marker(
                    point: selectedLine.routePoints[1],
                    width: 56,
                    height: 56,
                    child: GestureDetector(
                      onTap: () => _showBusInfo(context),
                      child: Container(
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
                        child: Center(
                          child: Text(
                            selectedLine.id,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_bus_rounded,
                          color: Color(0xFF1565C0),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<TransitLine>(
                              value: selectedLine,
                              isExpanded: true,
                              items: mockLines.map((line) {
                                return DropdownMenuItem(
                                  value: line,
                                  child: Text(
                                    '${line.name} - ${line.direction}',
                                  ),
                                );
                              }).toList(),
                              onChanged: (line) {
                                if (line == null) return;

                                setState(() {
                                  selectedLine = line;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.route,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedLine.direction,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBusInfo(BuildContext context) {
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
              Text(
                selectedLine.name,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(selectedLine.direction),
              const SizedBox(height: 10),
              const Text('Próxima parada: 4 min'),
              const SizedBox(height: 10),
              const Text('Status: Em operação'),
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
