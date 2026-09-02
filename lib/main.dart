import 'package:flutter/material.dart';

import 'pages/map_page.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
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
                      MaterialPageRoute(builder: (_) => const MapPage()),
                    );
                  },
                  icon: const Icon(Icons.map_rounded),
                  label: const Text(
                    'Ver Ã´nibus no mapa',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Rotas â€¢ Pontos â€¢ PrevisÃµes',
                style: TextStyle(fontSize: 14, color: Color(0xFF7A8495)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
