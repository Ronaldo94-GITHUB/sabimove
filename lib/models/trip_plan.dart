import 'package:latlong2/latlong.dart';

import 'transit_line.dart';
import 'transit_stop.dart';
import 'trip_leg.dart';

class TripPlan {
  final List<TripLeg> legs;
  final int estimatedMinutes;

  const TripPlan({required this.legs, required this.estimatedMinutes})
    : assert(legs.length > 0);

  bool get isDirect => legs.length == 1;

  TransitLine get line => legs.first.line;

  TransitStop get origin => legs.first.origin;

  TransitStop get destination => legs.last.destination;

  int get stopsTraveled {
    return legs.fold<int>(0, (total, leg) => total + leg.stopsTraveled);
  }

  List<LatLng> get routeSegment {
    return [for (final leg in legs) ...leg.routeSegment];
  }
}
