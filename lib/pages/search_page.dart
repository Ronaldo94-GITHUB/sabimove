import 'package:flutter/material.dart';

import '../data/mock_lines.dart';
import '../models/transit_line.dart';
import '../models/transit_stop.dart';

class TransitSearchSelection {
  final TransitLine line;
  final TransitStop? stop;

  const TransitSearchSelection({required this.line, this.stop});
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();

  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  bool _matches(String value) {
    if (query.trim().isEmpty) {
      return true;
    }

    return _normalize(value).contains(_normalize(query.trim()));
  }

  List<TransitLine> get matchingLines {
    return mockLines.where((line) {
      return _matches(line.name) ||
          _matches(line.direction) ||
          _matches(line.id);
    }).toList();
  }

  List<MapEntry<TransitLine, TransitStop>> get matchingStops {
    final results = <MapEntry<TransitLine, TransitStop>>[];

    for (final line in mockLines) {
      for (final stop in line.stops) {
        if (_matches(stop.name) ||
            _matches(stop.id) ||
            _matches(line.name) ||
            _matches(line.direction)) {
          results.add(MapEntry(line, stop));
        }
      }
    }

    return results;
  }

  bool get hasResults => matchingLines.isNotEmpty || matchingStops.isNotEmpty;

  void _selectLine(TransitLine line) {
    Navigator.of(context).pop(TransitSearchSelection(line: line));
  }

  void _selectStop(TransitLine line, TransitStop stop) {
    Navigator.of(context).pop(TransitSearchSelection(line: line, stop: stop));
  }

  @override
  Widget build(BuildContext context) {
    final lines = matchingLines;
    final stops = matchingStops;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buscar no SabiMove',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: TextField(
              controller: searchController,
              autofocus: true,
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Linha, sentido ou parada...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: () {
                          searchController.clear();

                          setState(() {
                            query = '';
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    query.trim().isEmpty
                        ? 'Digite algo ou explore as linhas e paradas disponíveis.'
                        : '${lines.length} linha(s) • ${stops.length} parada(s)',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: !hasResults
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum resultado encontrado',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tente pesquisar por outro nome, linha, sentido ou parada.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      if (lines.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.directions_bus,
                                color: Color(0xFF1565C0),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Linhas',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        ...lines.map(
                          (line) => Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  line.id,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(line.name),
                              subtitle: Text(line.direction),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _selectLine(line),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],

                      if (stops.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.deepOrange),
                              SizedBox(width: 8),
                              Text(
                                'Paradas',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        ...stops.map((entry) {
                          final line = entry.key;
                          final stop = entry.value;

                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.location_on),
                              ),
                              title: Text(stop.name),
                              subtitle: Text(
                                '${line.name} • ${line.direction}\n'
                                '${stop.id} • Ordem ${stop.sequence}',
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _selectStop(line, stop),
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: 12),

                      const Center(
                        child: Text(
                          'Dados de transporte simulados para desenvolvimento.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
