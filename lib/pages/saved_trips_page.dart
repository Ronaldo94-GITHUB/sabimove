import 'package:flutter/material.dart';

import '../data/mock_lines.dart';
import '../models/saved_trip.dart';
import '../models/trip_preference.dart';
import '../services/trip_history_service.dart';

class SavedTripsPage extends StatefulWidget {
  const SavedTripsPage({super.key});

  @override
  State<SavedTripsPage> createState() => _SavedTripsPageState();
}

class _SavedTripsPageState extends State<SavedTripsPage> {
  final TripHistoryService _historyService = TripHistoryService();

  List<SavedTrip> _trips = <SavedTrip>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final trips = await _historyService.loadTrips();

    if (!mounted) {
      return;
    }

    setState(() {
      _trips = trips;
      _loading = false;
    });
  }

  String _stopName(String stopId) {
    for (final line in mockLines) {
      for (final stop in line.stops) {
        if (stop.id == stopId) {
          return stop.name;
        }
      }
    }

    return stopId;
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

  String _formatDate(DateTime value) {
    final local = value.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/${local.year} • $hour:$minute';
  }

  Future<void> _toggleFavorite(SavedTrip trip) async {
    final updated = await _historyService.toggleFavorite(trip.storageKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _trips = updated;
    });
  }

  Future<void> _removeTrip(SavedTrip trip) async {
    final updated = await _historyService.removeTrip(trip.storageKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _trips = updated;
    });
  }

  Future<void> _clearHistory() async {
    final updated = await _historyService.clearHistoryKeepFavorites();

    if (!mounted) {
      return;
    }

    setState(() {
      _trips = updated;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Histórico limpo. As rotas favoritas foram mantidas.'),
      ),
    );
  }

  Widget _tripCard(SavedTrip trip) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        leading: CircleAvatar(
          child: Icon(trip.isFavorite ? Icons.star : Icons.history),
        ),
        title: Text(
          '${_stopName(trip.originStopId)} → ${_stopName(trip.destinationStopId)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${_preferenceLabel(trip.preference)}\n${_formatDate(trip.updatedAt)}',
          ),
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 0,
          children: [
            IconButton(
              tooltip: trip.isFavorite
                  ? 'Remover dos favoritos'
                  : 'Adicionar aos favoritos',
              onPressed: () => _toggleFavorite(trip),
              icon: Icon(
                trip.isFavorite ? Icons.star : Icons.star_border,
                color: trip.isFavorite ? Colors.amber : null,
              ),
            ),
            IconButton(
              tooltip: 'Excluir',
              onPressed: () => _removeTrip(trip),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).pop(trip);
        },
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<SavedTrip> trips,
  }) {
    if (trips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1565C0)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...trips.map(_tripCard),
        const SizedBox(height: 18),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = _trips.where((trip) => trip.isFavorite).toList();

    final history = _trips.where((trip) => !trip.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas viagens'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              tooltip: 'Limpar histórico',
              onPressed: _clearHistory,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.route_outlined, size: 58, color: Colors.grey),
                    SizedBox(height: 14),
                    Text(
                      'Nenhuma viagem salva ainda',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Planeje uma viagem para criar o histórico e salve suas rotas favoritas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _section(
                  title: 'Favoritas',
                  icon: Icons.star,
                  trips: favorites,
                ),
                _section(
                  title: 'Histórico recente',
                  icon: Icons.history,
                  trips: history,
                ),
                const SizedBox(height: 8),
                const Text(
                  'As viagens são armazenadas localmente neste dispositivo. As rotas continuam usando dados simulados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
    );
  }
}
