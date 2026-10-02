import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/mock_lines.dart';
import '../models/transit_line.dart';
import '../models/transit_stop.dart';
import '../models/trip_leg.dart';
import '../models/trip_plan.dart';
import '../models/trip_preference.dart';
import '../models/trip_transfer.dart';
import '../services/trip_planner_service.dart';

class TripPlannerSelection {
  final TripPlan plan;

  const TripPlannerSelection({required this.plan});
}

class TripPlannerPage extends StatefulWidget {
  final LatLng? initialUserPosition;

  const TripPlannerPage({super.key, this.initialUserPosition});

  @override
  State<TripPlannerPage> createState() => _TripPlannerPageState();
}

class _TripPlannerPageState extends State<TripPlannerPage> {
  static const LatLng _agudosCenter = LatLng(-22.4694, -48.9875);

  static const List<Color> _legColors = <Color>[
    Color(0xFF1565C0),
    Color(0xFFFF6F00),
  ];

  final TripPlannerService _planner = const TripPlannerService();

  String? _originStopId;
  String? _destinationStopId;
  TripPlan? _plan;
  List<TripPlan> _plans = <TripPlan>[];
  TripPreference _preference = TripPreference.fastest;
  String? _message;
  String? _locationMessage;

  LatLng? _userPosition;
  double? _accessDistanceMeters;
  bool _usingMyLocationAsOrigin = false;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();

    final initialPosition = widget.initialUserPosition;

    if (initialPosition != null) {
      _applyUserPosition(initialPosition, updateState: false);
    }
  }

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

  TransitStop? _stopById(String stopId) {
    for (final stop in _allStops) {
      if (stop.id == stopId) {
        return stop;
      }
    }

    return null;
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  String _preferenceLabel(TripPreference preference) {
    switch (preference) {
      case TripPreference.fastest:
        return 'Mais rápida';
      case TripPreference.lessWalking:
        return 'Menos caminhada';
      case TripPreference.fewerTransfers:
        return 'Menos baldeações';
    }
  }

  IconData _preferenceIcon(TripPreference preference) {
    switch (preference) {
      case TripPreference.fastest:
        return Icons.bolt;
      case TripPreference.lessWalking:
        return Icons.directions_walk;
      case TripPreference.fewerTransfers:
        return Icons.sync_alt;
    }
  }

  Color _legColor(int index) {
    return _legColors[index % _legColors.length];
  }

  LatLng _transferMidpoint(TripTransfer transfer) {
    return LatLng(
      (transfer.fromStop.position.latitude +
              transfer.toStop.position.latitude) /
          2,
      (transfer.fromStop.position.longitude +
              transfer.toStop.position.longitude) /
          2,
    );
  }

  void _clearPlans() {
    _plan = null;
    _plans = <TripPlan>[];
    _message = null;
  }

  void _applyUserPosition(LatLng position, {required bool updateState}) {
    final nearestStop = _planner.nearestStopTo(position);

    final distance = _planner.distanceMeters(position, nearestStop.position);

    void apply() {
      _userPosition = position;
      _originStopId = nearestStop.id;
      _accessDistanceMeters = distance;
      _usingMyLocationAsOrigin = true;
      _clearPlans();
      _locationMessage =
          'Parada mais próxima: ${nearestStop.name} • ${_formatDistance(distance)}.';
    }

    if (updateState) {
      setState(apply);
    } else {
      apply();
    }
  }

  Future<void> _useMyLocation() async {
    if (_isLocating) {
      return;
    }

    setState(() {
      _isLocating = true;
      _locationMessage = null;
    });

    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) {
          return;
        }

        setState(() {
          _locationMessage = 'Permissão de localização não concedida.';
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) {
          return;
        }

        setState(() {
          _locationMessage = 'Localização bloqueada. Libere a permissão no navegador ou dispositivo.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) {
        return;
      }

      _applyUserPosition(
        LatLng(position.latitude, position.longitude),
        updateState: true,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _locationMessage = 'Não foi possível obter sua localização. Verifique a permissão do navegador ou dispositivo.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  void _planTrip() {
    final originId = _originStopId;
    final destinationId = _destinationStopId;

    if (originId == null || destinationId == null) {
      setState(() {
        _clearPlans();
        _message = 'Selecione a origem e o destino.';
      });
      return;
    }

    final plans = _planner.findPlans(
      originStopId: originId,
      destinationStopId: destinationId,
      preference: _preference,
      maxResults: 3,
    );

    setState(() {
      _plans = plans;
      _plan = plans.isEmpty ? null : plans.first;
      _message = plans.isEmpty
          ? 'Não encontrei uma rota direta nem uma rota com 1 baldeação usando as conexões simuladas atuais.'
          : null;
    });
  }

  void _changePreference(TripPreference preference) {
    if (_preference == preference) {
      return;
    }

    setState(() {
      _preference = preference;
    });

    if (_originStopId != null && _destinationStopId != null) {
      _planTrip();
    }
  }

  void _selectPlan(TripPlan plan) {
    setState(() {
      _plan = plan;
    });
  }

  void _swapStops() {
    setState(() {
      final previousOrigin = _originStopId;
      _originStopId = _destinationStopId;
      _destinationStopId = previousOrigin;
      _clearPlans();
      _usingMyLocationAsOrigin = false;
      _accessDistanceMeters = null;
    });
  }

  LatLng _centerForPlan(TripPlan plan) {
    return LatLng(
      (plan.origin.position.latitude + plan.destination.position.latitude) / 2,
      (plan.origin.position.longitude + plan.destination.position.longitude) /
          2,
    );
  }

  String _planKey(TripPlan plan) {
    final lines = plan.legs.map((leg) => leg.line.id).join('-');

    final transfers = plan.transfers
        .map((transfer) => '${transfer.fromStop.id}-${transfer.toStop.id}')
        .join('-');

    return '$lines-${plan.origin.id}-${plan.destination.id}-$transfers';
  }

  Widget _mapMarker({
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
    final userPosition = _userPosition;

    final originStop = _originStopId == null ? null : _stopById(_originStopId!);

    final center = plan != null
        ? _centerForPlan(plan)
        : userPosition ?? _agudosCenter;

    final planLineIds =
        plan?.legs.map((leg) => leg.line.id).toSet() ?? const <String>{};

    return FlutterMap(
      key: ValueKey(
        plan != null
            ? _planKey(plan)
            : 'trip-planner-${userPosition?.latitude}-${userPosition?.longitude}-${_originStopId ?? 'empty'}',
      ),
      options: MapOptions(
        initialCenter: center,
        initialZoom: plan != null || userPosition != null ? 15 : 13.8,
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
                strokeWidth: planLineIds.contains(line.id) ? 5 : 3,
                color: planLineIds.contains(line.id)
                    ? const Color(0xFFBBDEFB)
                    : Colors.grey.withValues(alpha: 0.45),
              ),
            ),
            if (userPosition != null &&
                originStop != null &&
                _usingMyLocationAsOrigin)
              Polyline(
                points: [userPosition, originStop.position],
                strokeWidth: 4,
                color: Colors.green.shade700,
              ),
            if (plan != null)
              ...plan.legs.asMap().entries.map(
                (entry) => Polyline(
                  points: entry.value.routeSegment,
                  strokeWidth: 8,
                  color: _legColor(entry.key),
                ),
              ),
            if (plan != null)
              ...plan.transfers.map(
                (transfer) => Polyline(
                  points: [
                    transfer.fromStop.position,
                    transfer.toStop.position,
                  ],
                  strokeWidth: 4,
                  color: Colors.green.shade700,
                ),
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            if (userPosition != null)
              Marker(
                point: userPosition,
                width: 78,
                height: 70,
                child: _mapMarker(
                  label: 'Você',
                  icon: Icons.my_location,
                  color: const Color(0xFF1565C0),
                ),
              ),
            if (plan != null)
              Marker(
                point: plan.origin.position,
                width: 78,
                height: 70,
                child: _mapMarker(
                  label: 'Embarque',
                  icon: Icons.trip_origin,
                  color: Colors.green.shade700,
                ),
              ),
            if (plan != null)
              ...plan.transfers.map(
                (transfer) => Marker(
                  point: _transferMidpoint(transfer),
                  width: 88,
                  height: 70,
                  child: _mapMarker(
                    label: 'Baldeação',
                    icon: Icons.swap_horiz,
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
            if (plan != null)
              Marker(
                point: plan.destination.position,
                width: 88,
                height: 70,
                child: _mapMarker(
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
          _clearPlans();
        });
      },
    );
  }

  Widget _buildLocationCard() {
    final originStop = _originStopId == null ? null : _stopById(_originStopId!);

    return Card(
      elevation: 0,
      color: const Color(0xFF1565C0).withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.tonalIcon(
              onPressed: _isLocating ? null : _useMyLocation,
              icon: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                _isLocating ? 'Localizando...' : 'Usar minha localização',
              ),
            ),
            if (_locationMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _locationMessage!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            if (_usingMyLocationAsOrigin &&
                originStop != null &&
                _accessDistanceMeters != null) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.directions_walk,
                    size: 19,
                    color: Color(0xFF1565C0),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Embarque sugerido: ${originStop.name} • ${_formatDistance(_accessDistanceMeters!)} até a parada.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                'Distância aproximada entre as coordenadas; não representa uma rota de caminhada pelas ruas.',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prioridade do planejamento',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TripPreference.values
              .map(
                (preference) => ChoiceChip(
                  selected: _preference == preference,
                  avatar: Icon(_preferenceIcon(preference), size: 17),
                  label: Text(_preferenceLabel(preference)),
                  onSelected: (_) {
                    _changePreference(preference);
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildAlternativeSelector() {
    if (_plans.length <= 1) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: Colors.grey.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_plans.length} alternativas encontradas',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Ordenadas por: ${_preferenceLabel(_preference)}.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            ..._plans.asMap().entries.map((entry) {
              final index = entry.key;
              final plan = entry.value;
              final selected = identical(_plan, plan);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _selectPlan(plan),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF1565C0)
                            : Colors.grey.withValues(alpha: 0.3),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.legs
                                    .map((leg) => leg.line.name)
                                    .join(' → '),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${plan.estimatedMinutes} min • '
                                '${_formatDistance(plan.transferWalkingDistanceMeters)} a pé • '
                                '${plan.transferCount} baldeação(ões)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF1565C0),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLegCard(int index, TripLeg leg) {
    final color = _legColor(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: color,
                foregroundColor: Colors.white,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '${leg.line.name} • ${leg.line.direction}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${leg.origin.name} → ${leg.destination.name}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          Text(
            '${leg.stopsTraveled} etapa(s) • ${leg.estimatedMinutes} min simulados',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferCard(TripTransfer transfer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.directions_walk, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Baldeação',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('${transfer.fromStop.name} → ${transfer.toStop.name}'),
                const SizedBox(height: 4),
                Text(
                  '${_formatDistance(transfer.walkingDistanceMeters)} • '
                  '${transfer.walkingMinutes} min a pé + '
                  '${transfer.bufferMinutes} min de integração',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(TripPlan plan) {
    final routeLabel = plan.legs.map((leg) => leg.line.name).join(' → ');

    return Card(
      elevation: 0,
      color: const Color(0xFF1565C0).withValues(alpha: 0.07),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Viagem selecionada',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: plan.isDirect
                        ? Colors.green.shade100
                        : Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    plan.isDirect
                        ? 'Direta'
                        : '${plan.transferCount} baldeação',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _infoRow(
              icon: Icons.tune,
              label: 'Prioridade',
              value: _preferenceLabel(_preference),
            ),
            _infoRow(icon: Icons.route, label: 'Rota', value: routeLabel),
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
            if (_usingMyLocationAsOrigin && _accessDistanceMeters != null)
              _infoRow(
                icon: Icons.directions_walk,
                label: 'Até embarque',
                value: _formatDistance(_accessDistanceMeters!),
              ),
            _infoRow(
              icon: Icons.sync_alt,
              label: 'Baldeações',
              value: '${plan.transferCount}',
            ),
            _infoRow(
              icon: Icons.directions_walk,
              label: 'Caminhada',
              value: _formatDistance(plan.transferWalkingDistanceMeters),
            ),
            _infoRow(
              icon: Icons.schedule,
              label: 'Tempo total',
              value: '${plan.estimatedMinutes} min',
            ),
            const SizedBox(height: 10),
            ...plan.legs.asMap().entries.expand((entry) {
              final index = entry.key;

              final widgets = <Widget>[_buildLegCard(index, entry.value)];

              if (index < plan.transfers.length) {
                widgets.add(_buildTransferCard(plan.transfers[index]));
              }

              return widgets;
            }),
            const SizedBox(height: 4),
            Text(
              plan.isDirect
                  ? 'A rota e o tempo do ônibus são simulados para desenvolvimento.'
                  : 'A rota, os tempos e a conexão entre paradas próximas são simulados para desenvolvimento. A baldeação permite caminhada de até ${TripPlannerService.maxTransferWalkMeters.round()} m.',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(TripPlannerSelection(plan: plan));
                },
                icon: const Icon(Icons.map),
                label: const Text('Voltar ao mapa principal'),
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
            'Use sua localização ou escolha manualmente uma parada de origem.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildLocationCard(),
          const SizedBox(height: 16),
          _buildStopDropdown(
            label: 'Origem',
            value: _originStopId,
            icon: Icons.trip_origin,
            onChanged: (value) {
              _originStopId = value;
              _usingMyLocationAsOrigin = false;
              _accessDistanceMeters = null;
              _locationMessage = null;
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
          _buildPreferenceSelector(),
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
          if (_plans.length > 1) ...[
            const SizedBox(height: 16),
            _buildAlternativeSelector(),
          ],
          if (_plan != null) ...[
            const SizedBox(height: 16),
            _buildPlanCard(_plan!),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'V1.3 • Rotas inteligentes',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'O planejador compara até 3 alternativas simuladas e permite priorizar menor tempo, menor caminhada ou menos baldeações. As viagens continuam limitadas a rota direta ou 1 baldeação.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                SizedBox(width: 470, child: _buildPlannerPanel()),
                const VerticalDivider(width: 1),
                Expanded(child: _buildMap()),
              ],
            );
          }

          return Column(
            children: [
              Expanded(flex: 5, child: _buildMap()),
              const Divider(height: 1),
              Expanded(flex: 9, child: _buildPlannerPanel()),
            ],
          );
        },
      ),
    );
  }
}
