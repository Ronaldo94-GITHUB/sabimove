import 'package:latlong2/latlong.dart';

import '../models/transit_line.dart';

const mockLines = <TransitLine>[
  TransitLine(
    id: '01',
    name: 'Linha 01',
    direction: 'Centro → Bairro',
    routePoints: [
      LatLng(-22.4710, -48.9940),
      LatLng(-22.4698, -48.9915),
      LatLng(-22.4694, -48.9875),
      LatLng(-22.4688, -48.9830),
      LatLng(-22.4675, -48.9785),
    ],
    stops: [
      LatLng(-22.4710, -48.9940),
      LatLng(-22.4694, -48.9875),
      LatLng(-22.4675, -48.9785),
    ],
  ),
  TransitLine(
    id: '02',
    name: 'Linha 02',
    direction: 'Centro → Zona Leste',
    routePoints: [
      LatLng(-22.4725, -48.9905),
      LatLng(-22.4700, -48.9870),
      LatLng(-22.4680, -48.9830),
      LatLng(-22.4665, -48.9790),
    ],
    stops: [
      LatLng(-22.4725, -48.9905),
      LatLng(-22.4680, -48.9830),
      LatLng(-22.4665, -48.9790),
    ],
  ),
  TransitLine(
    id: '03',
    name: 'Linha 03',
    direction: 'Centro → Zona Sul',
    routePoints: [
      LatLng(-22.4685, -48.9930),
      LatLng(-22.4705, -48.9900),
      LatLng(-22.4720, -48.9865),
      LatLng(-22.4740, -48.9830),
    ],
    stops: [
      LatLng(-22.4685, -48.9930),
      LatLng(-22.4720, -48.9865),
      LatLng(-22.4740, -48.9830),
    ],
  ),
];
