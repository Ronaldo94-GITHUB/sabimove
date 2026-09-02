import 'package:latlong2/latlong.dart';

import '../models/transit_line.dart';
import '../models/transit_stop.dart';

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
      TransitStop(
        id: 'L01-P01',
        name: 'Ponto Centro',
        position: LatLng(-22.4710, -48.9940),
        sequence: 1,
      ),
      TransitStop(
        id: 'L01-P02',
        name: 'Ponto Intermediário',
        position: LatLng(-22.4694, -48.9875),
        sequence: 2,
      ),
      TransitStop(
        id: 'L01-P03',
        name: 'Ponto Bairro',
        position: LatLng(-22.4675, -48.9785),
        sequence: 3,
      ),
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
      TransitStop(
        id: 'L02-P01',
        name: 'Ponto Centro Leste',
        position: LatLng(-22.4725, -48.9905),
        sequence: 1,
      ),
      TransitStop(
        id: 'L02-P02',
        name: 'Ponto Leste',
        position: LatLng(-22.4680, -48.9830),
        sequence: 2,
      ),
      TransitStop(
        id: 'L02-P03',
        name: 'Terminal Leste',
        position: LatLng(-22.4665, -48.9790),
        sequence: 3,
      ),
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
      TransitStop(
        id: 'L03-P01',
        name: 'Ponto Centro Sul',
        position: LatLng(-22.4685, -48.9930),
        sequence: 1,
      ),
      TransitStop(
        id: 'L03-P02',
        name: 'Ponto Sul',
        position: LatLng(-22.4720, -48.9865),
        sequence: 2,
      ),
      TransitStop(
        id: 'L03-P03',
        name: 'Terminal Sul',
        position: LatLng(-22.4740, -48.9830),
        sequence: 3,
      ),
    ],
  ),
];
