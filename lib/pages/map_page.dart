import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/mock_buses.dart';
import '../data/mock_lines.dart';
import '../models/transit_bus.dart';
import '../models/transit_line.dart';
import '../models/transit_stop.dart';

import 'search_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  TransitLine selectedLine = mockLines.first;

  late List<TransitBus> buses;
  Timer? movementTimer;

  final Set<String> favoriteStopIds = <String>{};
  final Set<String> favoriteLineIds = <String>{};

  int get favoriteCount => favoriteStopIds.length + favoriteLineIds.length;

  bool _isLineFavorite(TransitLine line) {
    return favoriteLineIds.contains(line.id);
  }

  void _toggleLineFavorite(TransitLine line) {
    setState(() {
      if (_isLineFavorite(line)) {
        favoriteLineIds.remove(line.id);
      } else {
        favoriteLineIds.add(line.id);
      }
    });
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
    for (final line in mockLines) {
      for (final stop in line.stops) {
        if (stop.id == stopId) {
          return stop;
        }
      }
    }

    return null;
  }

  bool _isStopFavorite(TransitStop stop) {
    return favoriteStopIds.contains(stop.id);
  }

  void _toggleStopFavorite(TransitStop stop) {
    setState(() {
      if (_isStopFavorite(stop)) {
        favoriteStopIds.remove(stop.id);
      } else {
        favoriteStopIds.add(stop.id);
      }
    });
  }

  void _showFavorites(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) {
        final favoriteLines = mockLines
            .where((line) => favoriteLineIds.contains(line.id))
            .toList();

        final favoriteStops = favoriteStopIds
            .map(_stopById)
            .whereType<TransitStop>()
            .toList();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Meus favoritos',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$favoriteCount favorito(s)',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 18),

                  if (favoriteCount == 0)
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_border,
                              size: 54,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Nenhum favorito ainda',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Favorite linhas e paradas para encontrÃƒÂ¡-las rapidamente.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView(
                        children: [
                          if (favoriteLines.isNotEmpty) ...[
                            const Text(
                              'Linhas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            ...favoriteLines.map(
                              (line) => Card(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.directions_bus),
                                  ),
                                  title: Text(line.name),
                                  subtitle: Text(line.direction),
                                  trailing: IconButton(
                                    tooltip: 'Remover dos favoritos',
                                    icon: const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    onPressed: () {
                                      _toggleLineFavorite(line);
                                      Navigator.of(context).pop();
                                      _showFavorites(context);
                                    },
                                  ),
                                  onTap: () {
                                    setState(() {
                                      selectedLine = line;
                                    });

                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],

                          if (favoriteStops.isNotEmpty) ...[
                            const Text(
                              'Paradas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            ...favoriteStops.map((stop) {
                              final line = _lineForStop(stop.id);

                              return Card(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.location_on),
                                  ),
                                  title: Text(stop.name),
                                  subtitle: Text(
                                    line == null
                                        ? stop.id
                                        : '${line.name} Ã¢â‚¬Â¢ ${line.direction}',
                                  ),
                                  trailing: IconButton(
                                    tooltip: 'Remover dos favoritos',
                                    icon: const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    onPressed: () {
                                      _toggleStopFavorite(stop);
                                      Navigator.of(context).pop();
                                      _showFavorites(context);
                                    },
                                  ),
                                  onTap: () {
                                    if (line != null) {
                                      setState(() {
                                        selectedLine = line;
                                      });
                                    }

                                    Navigator.of(context).pop();

                                    Future.microtask(() {
                                      if (!context.mounted) {
                                        return;
                                      }

                                      _showStopInfo(context, stop);
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  const Text(
                    'Favoritos armazenados temporariamente nesta versÃƒÂ£o.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSearch(BuildContext context) async {
    final selection = await Navigator.of(context).push<TransitSearchSelection>(
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );

    if (!context.mounted || selection == null) {
      return;
    }

    setState(() {
      selectedLine = selection.line;
    });

    final stop = selection.stop;

    if (stop == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }

      _showStopInfo(context, stop);
    });
  }

  @override
  void initState() {
    super.initState();

    buses = mockBuses.map((bus) => bus.copyWith()).toList();

    movementTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _moveBuses(),
    );
  }

  @override
  void dispose() {
    movementTimer?.cancel();
    super.dispose();
  }

  List<TransitBus> get selectedBuses {
    return buses.where((bus) => bus.lineId == selectedLine.id).toList();
  }

  void _moveBuses() {
    if (!mounted) return;

    setState(() {
      buses = buses.map((bus) {
        var newProgress = bus.progress + 0.025;

        if (newProgress > 1.0) {
          newProgress = 0.0;
        }

        return bus.copyWith(progress: newProgress);
      }).toList();
    });
  }

  LatLng _positionFromProgress(TransitBus bus) {
    final points = selectedLine.routePoints;

    if (points.length == 1) {
      return points.first;
    }

    final progress = bus.progress.clamp(0.0, 1.0);
    final scaled = progress * (points.length - 1);

    final startIndex = scaled.floor();

    final endIndex = startIndex >= points.length - 1
        ? startIndex
        : startIndex + 1;

    final localProgress = scaled - startIndex;

    final start = points[startIndex];
    final end = points[endIndex];

    return LatLng(
      start.latitude + (end.latitude - start.latitude) * localProgress,
      start.longitude + (end.longitude - start.longitude) * localProgress,
    );
  }

  double _stopProgress(LatLng stop) {
    final points = selectedLine.routePoints;

    if (points.length <= 1) {
      return 0;
    }

    var closestIndex = 0;
    var closestDistance = double.infinity;

    for (var i = 0; i < points.length; i++) {
      final latDifference = points[i].latitude - stop.latitude;

      final lonDifference = points[i].longitude - stop.longitude;

      final distance =
          (latDifference * latDifference) + (lonDifference * lonDifference);

      if (distance < closestDistance) {
        closestDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex / (points.length - 1);
  }

  TransitStop _nextStopForBus(TransitBus bus) {
    final stops = selectedLine.stops;

    for (final stop in stops) {
      final progress = _stopProgress(stop.position);

      if (progress > bus.progress) {
        return stop;
      }
    }

    return stops.first;
  }

  int _etaForBus(TransitBus bus) {
    final nextStop = _nextStopForBus(bus);
    final nextStopProgress = _stopProgress(nextStop.position);

    double remainingProgress;

    if (nextStopProgress > bus.progress) {
      remainingProgress = nextStopProgress - bus.progress;
    } else {
      remainingProgress = (1 - bus.progress) + nextStopProgress;
    }

    const simulatedRouteMinutes = 18.0;

    final eta = (remainingProgress * simulatedRouteMinutes).ceil();

    return eta < 1 ? 1 : eta;
  }

  String _stopNameForBus(TransitBus bus) {
    final stop = _nextStopForBus(bus);
    return stop.name;
  }

  @override
  Widget build(BuildContext context) {
    const agudos = LatLng(-22.4694, -48.9875);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mapa SabiMove',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Buscar linhas e paradas',
            onPressed: () {
              _openSearch(context);
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: _isLineFavorite(selectedLine)
                ? 'Remover linha dos favoritos'
                : 'Favoritar linha',
            onPressed: () {
              _toggleLineFavorite(selectedLine);
            },
            icon: Icon(
              _isLineFavorite(selectedLine) ? Icons.star : Icons.star_border,
              color: _isLineFavorite(selectedLine) ? Colors.amber : null,
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Meus favoritos',
                onPressed: () {
                  _showFavorites(context);
                },
                icon: const Icon(Icons.bookmarks_outlined),
              ),
              if (favoriteCount > 0)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 17,
                      minHeight: 17,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$favoriteCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(initialCenter: agudos, initialZoom: 14),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                      point: stop.position,
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => _showStopInfo(context, stop),
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
                  ),
                  ...selectedBuses.map(
                    (bus) => Marker(
                      point: _positionFromProgress(bus),
                      width: 60,
                      height: 60,
                      child: GestureDetector(
                        onTap: () => _showBusInfo(context, bus),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(blurRadius: 6, color: Colors.black26),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.directions_bus,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                Text(
                                  bus.vehicleNumber,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
                                return DropdownMenuItem<TransitLine>(
                                  value: line,
                                  child: Text(
                                    '${line.name} - ${line.direction}',
                                  ),
                                );
                              }).toList(),
                              onChanged: (line) {
                                if (line == null) {
                                  return;
                                }

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
                        const Icon(Icons.route, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${selectedLine.direction} Ã¢â‚¬Â¢ '
                            '${selectedBuses.length} ÃƒÂ´nibus simulados',
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
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'SimulaÃƒÂ§ÃƒÂ£o ativa',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 20,
                          color: Color(0xFF1565C0),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'PrÃƒÂ³ximas chegadas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...selectedBuses.map((bus) {
                      final eta = _etaForBus(bus);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                bus.vehicleNumber,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_stopNameForBus(bus))),
                            Text(
                              '$eta min',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    const Text(
                      'Estimativas simuladas para desenvolvimento.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
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

  int _etaToStop(TransitBus bus, TransitStop stop) {
    final targetProgress = _stopProgress(stop.position);

    double remainingProgress;

    if (targetProgress > bus.progress) {
      remainingProgress = targetProgress - bus.progress;
    } else {
      remainingProgress = (1 - bus.progress) + targetProgress;
    }

    const simulatedRouteMinutes = 18.0;

    final eta = (remainingProgress * simulatedRouteMinutes).ceil();

    return eta < 1 ? 1 : eta;
  }

  void _showStopInfo(BuildContext context, TransitStop stop) {
    final arrivingBuses =
        buses
            .where((bus) => bus.lineId == selectedLine.id)
            .map((bus) => MapEntry(bus, _etaToStop(bus, stop)))
            .toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.deepOrange,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      stop.name,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _isStopFavorite(stop)
                        ? 'Remover dos favoritos'
                        : 'Adicionar aos favoritos',
                    onPressed: () {
                      _toggleStopFavorite(stop);
                      Navigator.of(context).pop();
                      _showStopInfo(context, stop);
                    },
                    icon: Icon(
                      _isStopFavorite(stop) ? Icons.star : Icons.star_border,
                      color: _isStopFavorite(stop) ? Colors.amber : Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Text('CÃƒÂ³digo da parada: ${stop.id}'),

              const SizedBox(height: 8),

              Text('Linha: ${selectedLine.name}'),

              const SizedBox(height: 8),

              Text('Sentido: ${selectedLine.direction}'),

              const SizedBox(height: 8),

              Text('Ordem na rota: ${stop.sequence}'),

              const SizedBox(height: 22),

              const Row(
                children: [
                  Icon(Icons.directions_bus, size: 21),
                  SizedBox(width: 8),
                  Text(
                    'PrÃƒÂ³ximos ÃƒÂ´nibus',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              ...arrivingBuses.map((entry) {
                final bus = entry.key;
                final eta = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        child: Text(
                          bus.vehicleNumber,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ãƒâ€nibus ${bus.vehicleNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '$eta min',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 10),

              const Text(
                'Tempos e posiÃƒÂ§ÃƒÂµes simulados para desenvolvimento.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBusInfo(BuildContext context, TransitBus bus) {
    final eta = _etaForBus(bus);
    final nextStop = _stopNameForBus(bus);

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
              Text('Ãƒâ€nibus ${bus.vehicleNumber}'),
              const SizedBox(height: 10),
              Text(selectedLine.direction),
              const SizedBox(height: 10),
              Text('PrÃƒÂ³xima parada: $nextStop'),
              const SizedBox(height: 6),
              Text('PrevisÃƒÂ£o de chegada: $eta min'),
              const SizedBox(height: 10),
              const Text('Status: Em operaÃƒÂ§ÃƒÂ£o'),
              const SizedBox(height: 18),
              const Text(
                'PosiÃƒÂ§ÃƒÂ£o e previsÃƒÂ£o atualizadas automaticamente.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              const Text(
                'Dados simulados para desenvolvimento.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}
