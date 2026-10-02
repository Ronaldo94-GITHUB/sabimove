import 'package:latlong2/latlong.dart';

import 'transit_line.dart';
import 'transit_stop.dart';

class TripLeg {
  final TransitLine line;
  final TransitStop origin;
  final TransitStop destination;
  final List<LatLng> routeSegment;
  final int stopsTraveled;
  final int estimatedMinutes;

  const TripLeg({
    required this.line,
    required this.origin,
    required this.destination,
    required this.routeSegment,
    required this.stopsTraveled,
    required this.estimatedMinutes,
  });
}
