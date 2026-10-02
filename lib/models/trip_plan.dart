import 'package:latlong2/latlong.dart';

import 'transit_line.dart';
import 'transit_stop.dart';
import 'trip_leg.dart';
import 'trip_transfer.dart';

class TripPlan {
  final List<TripLeg> legs;
  final List<TripTransfer> transfers;
  final int estimatedMinutes;

  const TripPlan({
    required this.legs,
    this.transfers = const <TripTransfer>[],
    required this.estimatedMinutes,
  }) : assert(legs.length > 0),
       assert(transfers.length <= legs.length - 1);

  bool get isDirect => transfers.isEmpty;

  int get transferCount => transfers.length;

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
