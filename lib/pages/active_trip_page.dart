import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../models/trip_guidance_step.dart';
import '../models/trip_plan.dart';
import '../services/trip_guidance_service.dart';

class ActiveTripPage extends StatefulWidget {
  final TripPlan plan;

  const ActiveTripPage({super.key, required this.plan});

  @override
  State<ActiveTripPage> createState() => _ActiveTripPageState();
}

class _ActiveTripPageState extends State<ActiveTripPage> {
  static const List<Color> _legColors = <Color>[
    Color(0xFF1565C0),
    Color(0xFFFF6F00),
  ];

  final TripGuidanceService _guidanceService = const TripGuidanceService();

  late final List<TripGuidanceStep> _steps;

  int _currentIndex = 0;
  bool _automaticSimulation = false;
  bool _completed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _steps = _guidanceService.buildSteps(widget.plan);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  TripGuidanceStep get _currentStep {
    return _steps[_currentIndex];
  }

  double get _progress {
    if (_steps.isEmpty) {
      return 0;
    }

    if (_completed) {
      return 1;
    }

    return (_currentIndex + 1) / _steps.length;
  }

  Color _legColor(int index) {
    return _legColors[index % _legColors.length];
  }

  IconData _stepIcon(TripGuidanceStepType type) {
    switch (type) {
      case TripGuidanceStepType.board:
        return Icons.directions_bus;
      case TripGuidanceStepType.ride:
        return Icons.location_on_outlined;
      case TripGuidanceStepType.walkTransfer:
        return Icons.directions_walk;
      case TripGuidanceStepType.arrive:
        return Icons.flag;
    }
  }

  Color _stepColor(TripGuidanceStepType type) {
    switch (type) {
      case TripGuidanceStepType.board:
        return const Color(0xFF1565C0);
      case TripGuidanceStepType.ride:
        return Colors.indigo;
      case TripGuidanceStepType.walkTransfer:
        return Colors.green.shade700;
      case TripGuidanceStepType.arrive:
        return Colors.deepOrange;
    }
  }

  void _setAutomaticSimulation(bool enabled) {
    _timer?.cancel();

    setState(() {
      _automaticSimulation = enabled && !_completed;
    });

    if (!_automaticSimulation) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _advance());
  }

  void _advance() {
    if (_completed || _steps.isEmpty) {
      return;
    }

    if (_currentIndex >= _steps.length - 1) {
      setState(() {
        _completed = true;
        _automaticSimulation = false;
      });

      _timer?.cancel();
      _showStepAlert(_currentStep);
      return;
    }

    setState(() {
      _currentIndex++;

      if (_currentIndex == _steps.length - 1) {
        _completed = true;
        _automaticSimulation = false;
      }
    });

    if (_completed) {
      _timer?.cancel();
    }

    _showStepAlert(_currentStep);
  }

  void _goBackStep() {
    if (_currentIndex == 0) {
      return;
    }

    _timer?.cancel();

    setState(() {
      _currentIndex--;
      _completed = false;
      _automaticSimulation = false;
    });
  }

  void _showStepAlert(TripGuidanceStep step) {
    String? message;

    switch (step.type) {
      case TripGuidanceStepType.board:
        message = 'Hora de embarcar: ${step.instruction}';
        break;
      case TripGuidanceStepType.ride:
        if (step.title.contains('baldeação')) {
          message = 'Atenção: prepare-se para a baldeação.';
        }
        break;
      case TripGuidanceStepType.walkTransfer:
        message = 'Baldeação: ${step.instruction}';
        break;
      case TripGuidanceStepType.arrive:
        message = 'Você chegou ao destino da simulação.';
        break;
    }

    if (message == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
  }

  Future<void> _cancelTrip() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancelar viagem?'),
          content: const Text(
            'O acompanhamento atual será encerrado. '
            'O histórico e as rotas favoritas não serão apagados.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Continuar viagem'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Cancelar viagem'),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildMap() {
    final current = _currentStep.position;

    return FlutterMap(
      key: ValueKey('active-${widget.plan.signature}-$_currentIndex'),
      options: MapOptions(initialCenter: current, initialZoom: 15.2),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'br.com.sabinoai.sabimove',
        ),
        PolylineLayer(
          polylines: [
            ...widget.plan.legs.asMap().entries.map(
              (entry) => Polyline(
                points: entry.value.routeSegment,
                strokeWidth: 7,
                color: _legColor(entry.key),
              ),
            ),
            ...widget.plan.transfers.map(
              (transfer) => Polyline(
                points: [transfer.fromStop.position, transfer.toStop.position],
                strokeWidth: 4,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: widget.plan.origin.position,
              width: 46,
              height: 46,
              child: const Icon(
                Icons.trip_origin,
                color: Colors.green,
                size: 32,
              ),
            ),
            Marker(
              point: widget.plan.destination.position,
              width: 46,
              height: 46,
              child: const Icon(Icons.flag, color: Colors.red, size: 32),
            ),
            Marker(
              point: current,
              width: 58,
              height: 58,
              child: Container(
                decoration: BoxDecoration(
                  color: _stepColor(_currentStep.type),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(blurRadius: 8, color: Colors.black26),
                  ],
                ),
                child: Icon(
                  _stepIcon(_currentStep.type),
                  color: Colors.white,
                  size: 27,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentInstruction() {
    final step = _currentStep;
    final color = _stepColor(step.type);

    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  child: Icon(_stepIcon(step.type), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _completed ? 'Viagem concluída' : step.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        step.instruction,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.detail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(height: 7),
            Text(
              _completed
                  ? '100% • acompanhamento finalizado'
                  : 'Etapa ${_currentIndex + 1} de ${_steps.length} • ${(_progress * 100).round()}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Etapas da viagem',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ..._steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isCurrent = index == _currentIndex;
          final isDone = index < _currentIndex || _completed;
          final color = _stepColor(step.type);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: isCurrent ? color.withValues(alpha: 0.08) : null,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCurrent ? color : Colors.grey.withValues(alpha: 0.2),
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isDone ? Icons.check_circle : _stepIcon(step.type),
                  color: isDone ? Colors.green : color,
                  size: 21,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.instruction,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildControlPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.plan.origin.name} → ${widget.plan.destination.name}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            '${widget.plan.estimatedMinutes} min simulados • '
            '${widget.plan.transferCount} baldeação(ões)',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildCurrentInstruction(),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Simulação automática',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Avança uma etapa a cada 4 segundos enquanto esta tela estiver aberta.',
            ),
            value: _automaticSimulation,
            onChanged: _completed ? null : _setAutomaticSimulation,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentIndex > 0 ? _goBackStep : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Voltar etapa'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _completed ? null : _advance,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Avançar'),
                ),
              ),
            ],
          ),
          if (_completed) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check),
              label: const Text('Finalizar acompanhamento'),
            ),
          ],
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _cancelTrip,
            icon: const Icon(Icons.close),
            label: const Text('Cancelar viagem'),
          ),
          const SizedBox(height: 18),
          _buildTimeline(),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'V1.5 • Acompanhamento da viagem',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'O progresso e os alertas desta fase são simulados para desenvolvimento. '
            'Não representam rastreamento em tempo real nem notificações em segundo plano.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_steps.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Não foi possível criar o acompanhamento desta viagem.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.navigation),
            SizedBox(width: 8),
            Text('Viagem em andamento'),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          if (isDesktop) {
            return Row(
              children: [
                SizedBox(width: 470, child: _buildControlPanel()),
                const VerticalDivider(width: 1),
                Expanded(child: _buildMap()),
              ],
            );
          }

          return Column(
            children: [
              Expanded(flex: 5, child: _buildMap()),
              const Divider(height: 1),
              Expanded(flex: 9, child: _buildControlPanel()),
            ],
          );
        },
      ),
    );
  }
}
