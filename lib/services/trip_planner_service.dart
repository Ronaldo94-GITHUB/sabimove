import 'package:latlong2/latlong.dart';

import '../data/mock_lines.dart';
import '../models/transit_line.dart';
import '../models/transit_stop.dart';
import '../models/trip_plan.dart';

class TripPlannerService {
  const TripPlannerService();

  TripPlan? findDirectPlan({
    required String originStopId,
    required String destinationStopId,
  }) {
    if (originStopId == destinationStopId) {
      return null;
    }

    for (final line in mockLines) {
      TransitStop? origin;
      TransitStop? destination;

      for (final stop in line.stops) {
        if (stop.id == originStopId) {
          origin = stop;
        }
        if (stop.id == destinationStopId) {
          destination = stop;
        }
      }

      if (origin == null || destination == null) {
        continue;
      }

      if (destination.sequence <= origin.sequence) {
        return null;
      }

      final stopsTraveled = destination.sequence - origin.sequence;
      final routeSegment = _routeSegment(
        line: line,
        origin: origin,
        destination: destination,
      );

      var estimatedMinutes = 1;
      if (line.stops.length > 1) {
        const simulatedFullRouteMinutes = 18.0;
        final fraction = stopsTraveled / (line.stops.length - 1);
        estimatedMinutes = (fraction * simulatedFullRouteMinutes).ceil();
        if (estimatedMinutes < 1) {
          estimatedMinutes = 1;
        }
      }

      return TripPlan(
        line: line,
        origin: origin,
        destination: destination,
        routeSegment: routeSegment,
        stopsTraveled: stopsTraveled,
        estimatedMinutes: estimatedMinutes,
      );
    }

    return null;
  }

  List<LatLng> _routeSegment({
    required TransitLine line,
    required TransitStop origin,
    required TransitStop destination,
  }) {
    final startIndex = _nearestRoutePointIndex(line, origin.position);
    final endIndex = _nearestRoutePointIndex(line, destination.position);

    if (endIndex < startIndex) {
      return <LatLng>[origin.position, destination.position];
    }

    final segment = line.routePoints.sublist(startIndex, endIndex + 1);

    if (segment.length == 1) {
      return <LatLng>[origin.position, destination.position];
    }

    return segment;
  }

  int _nearestRoutePointIndex(TransitLine line, LatLng point) {
    var nearestIndex = 0;
    var nearestDistance = double.infinity;

    for (var index = 0; index < line.routePoints.length; index++) {
      final candidate = line.routePoints[index];
      final latDifference = candidate.latitude - point.latitude;
      final lonDifference = candidate.longitude - point.longitude;
      final distance =
          (latDifference * latDifference) + (lonDifference * lonDifference);

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = index;
      }
    }

    return nearestIndex;
  }
}
