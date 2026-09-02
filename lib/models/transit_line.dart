import 'package:latlong2/latlong.dart';

import 'transit_stop.dart';

class TransitLine {
  final String id;
  final String name;
  final String direction;
  final List<LatLng> routePoints;
  final List<TransitStop> stops;

  const TransitLine({
    required this.id,
    required this.name,
    required this.direction,
    required this.routePoints,
    required this.stops,
  });
}
