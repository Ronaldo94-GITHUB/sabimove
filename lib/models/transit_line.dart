import 'package:latlong2/latlong.dart';

class TransitLine {
  final String id;
  final String name;
  final String direction;
  final List<LatLng> routePoints;
  final List<LatLng> stops;

  const TransitLine({
    required this.id,
    required this.name,
    required this.direction,
    required this.routePoints,
    required this.stops,
  });
}
