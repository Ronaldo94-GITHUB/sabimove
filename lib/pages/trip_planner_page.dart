import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/mock_lines.dart';
import '../models/transit_line.dart';
import '../models/transit_stop.dart';
import '../models/trip_plan.dart';
import '../services/trip_planner_service.dart';

class TripPlannerSelection {
  final TripPlan plan;

  const TripPlannerSelection({required this.plan});
}

class TripPlannerPage extends StatefulWidget {
  const TripPlannerPage({super.key});

  @override
  State<TripPlannerPage> createState() => _TripPlannerPageState();
}

class _TripPlannerPageState extends State<TripPlannerPage> {
  static const LatLng _agudosCenter = LatLng(-22.4694, -48.9875);

  final TripPlannerService _planner = const TripPlannerService();

  String? _originStopId;
  String? _destinationStopId;
  TripPlan? _plan;
  String? _message;

  List<TransitStop> get _allStops {
    return mockLines.expand((line) => line.stops).toList();
  }

  TransitLine? _lineForStop(String stopId) {
    for (final line in mockLines) {
      for (final stop in line.stops) {
        if (stop.id == stopId) {
          return line;
        }
      }
    }
    return null;
  }

  void _planTrip() {
    final originId = _originStopId;
    final destinationId = _destinationStopId;

    if (originId == null || destinationId == null) {
      setState(() {
        _plan = null;
        _message = 'Selecione a origem e o destino.';
      });
      return;
    }

    final plan = _planner.findDirectPlan(
      originStopId: originId,
      destinationStopId: destinationId,
    );

    setState(() {
      _plan = plan;
      _message = plan == null
          ? 'Não há uma viagem direta nesse sentido usando os dados simulados atuais.'
          : null;
    });
  }

  void _swapStops() {
    setState(() {
      final previousOrigin = _originStopId;
      _originStopId = _destinationStopId;
      _destinationStopId = previousOrigin;
      _plan = null;
      _message = null;
    });
  }

  LatLng _centerForPlan(TripPlan plan) {
    return LatLng(
      (plan.origin.position.latitude + plan.destination.position.latitude) / 2,
      (plan.origin.position.longitude + plan.destination.position.longitude) /
          2,
    );
  }

  Widget _stopMarker({
    required TransitStop stop,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    final plan = _plan;
    final center = plan == null ? _agudosCenter : _centerForPlan(plan);

    return FlutterMap(
      key: ValueKey(
        plan == null
            ? 'trip-planner-empty'
            : '${plan.line.id}-${plan.origin.id}-${plan.destination.id}',
      ),
      options: MapOptions(
        initialCenter: center,
        initialZoom: plan == null ? 13.8 : 15,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'br.com.sabinoai.sabimove',
        ),
        PolylineLayer(
          polylines: [
            ...mockLines.map(
              (line) => Polyline(
                points: line.routePoints,
                strokeWidth: plan?.line.id == line.id ? 5 : 3,
                color: plan?.line.id == line.id
                    ? const Color(0xFF90CAF9)
                    : Colors.grey.withValues(alpha: 0.45),
              ),
            ),
            if (plan != null)
              Polyline(
                points: plan.routeSegment,
                strokeWidth: 8,
                color: Colors.deepOrange,
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            if (plan != null)
              Marker(
                point: plan.origin.position,
                width: 78,
                height: 70,
                child: _stopMarker(
                  stop: plan.origin,
                  label: 'Embarque',
                  icon: Icons.trip_origin,
                  color: Colors.green.shade700,
                ),
              ),
            if (plan != null)
              Marker(
                point: plan.destination.position,
                width: 88,
                height: 70,
                child: _stopMarker(
                  stop: plan.destination,
                  label: 'Desembarque',
                  icon: Icons.flag,
                  color: Colors.red.shade700,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStopDropdown({
    required String label,
    required String? value,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      items: _allStops.map((stop) {
        final line = _lineForStop(stop.id);

        return DropdownMenuItem<String>(
          value: stop.id,
          child: Text(
            line == null ? stop.name : '${stop.name} • ${line.name}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (newValue) {
        onChanged(newValue);
        setState(() {
          _plan = null;
          _message = null;
        });
      },
    );
  }

  Widget _buildPlanCard(TripPlan plan) {
    return Card(
      elevation: 0,
      color: const Color(0xFF1565C0).withValues(alpha: 0.07),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Viagem encontrada',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _infoRow(
              icon: Icons.directions_bus,
              label: 'Linha',
              value: '${plan.line.name} • ${plan.line.direction}',
            ),
            _infoRow(
              icon: Icons.login,
              label: 'Embarque',
              value: plan.origin.name,
            ),
            _infoRow(
              icon: Icons.logout,
              label: 'Desembarque',
              value: plan.destination.name,
            ),
            _infoRow(
              icon: Icons.pin_drop,
              label: 'Trecho',
              value: '${plan.stopsTraveled} etapa(s) entre paradas',
            ),
            _infoRow(
              icon: Icons.schedule,
              label: 'Tempo estimado',
              value: '${plan.estimatedMinutes} min',
            ),
            const SizedBox(height: 8),
            const Text(
              'A rota e o tempo são simulados para desenvolvimento.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(TripPlannerSelection(plan: plan));
                },
                icon: const Icon(Icons.map),
                label: const Text('Ver no mapa principal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: const Color(0xFF1565C0)),
          const SizedBox(width: 9),
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildPlannerPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Planeje sua viagem',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Escolha uma parada de origem e uma parada de destino.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _buildStopDropdown(
            label: 'Origem',
            value: _originStopId,
            icon: Icons.trip_origin,
            onChanged: (value) {
              _originStopId = value;
            },
          ),
          const SizedBox(height: 10),
          Center(
            child: IconButton.filledTonal(
              tooltip: 'Inverter origem e destino',
              onPressed: _swapStops,
              icon: const Icon(Icons.swap_vert),
            ),
          ),
          const SizedBox(height: 10),
          _buildStopDropdown(
            label: 'Destino',
            value: _destinationStopId,
            icon: Icons.flag_outlined,
            onChanged: (value) {
              _destinationStopId = value;
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _planTrip,
            icon: const Icon(Icons.alt_route),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Planejar viagem'),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 14),
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.deepOrange),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_message!)),
                  ],
                ),
              ),
            ),
          ],
          if (_plan != null) ...[
            const SizedBox(height: 16),
            _buildPlanCard(_plan!),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'V1.0 • Planejador direto',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Nesta versão, o planejador encontra viagens diretas no sentido cadastrado da linha. Integrações e baldeações ficam para uma evolução posterior.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.alt_route),
            SizedBox(width: 8),
            Text('Planejador de viagem'),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          if (isDesktop) {
            return Row(
              children: [
                SizedBox(width: 410, child: _buildPlannerPanel()),
                const VerticalDivider(width: 1),
                Expanded(child: _buildMap()),
              ],
            );
          }

          return Column(
            children: [
              Expanded(flex: 5, child: _buildMap()),
              const Divider(height: 1),
              Expanded(flex: 6, child: _buildPlannerPanel()),
            ],
          );
        },
      ),
    );
  }
}
