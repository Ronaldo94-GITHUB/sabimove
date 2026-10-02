import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../data/mock_lines.dart';
import '../models/transit_line.dart';
import '../models/transit_stop.dart';
import '../models/trip_leg.dart';
import '../models/trip_plan.dart';

class TripPlannerService {
  const TripPlannerService();

  TripPlan? findPlan({
    required String originStopId,
    required String destinationStopId,
  }) {
    return findDirectPlan(
      originStopId: originStopId,
      destinationStopId: destinationStopId,
    );
  }

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

      final leg = TripLeg(
        line: line,
        origin: origin,
        destination: destination,
        routeSegment: routeSegment,
        stopsTraveled: stopsTraveled,
        estimatedMinutes: estimatedMinutes,
      );

      return TripPlan(legs: [leg], estimatedMinutes: estimatedMinutes);
    }

    return null;
  }

  TransitStop nearestStopTo(LatLng position) {
    final stops = mockLines.expand((line) => line.stops).toList();

    if (stops.isEmpty) {
      throw StateError('Nenhuma parada cadastrada.');
    }

    var nearest = stops.first;
    var nearestDistance = distanceMeters(position, nearest.position);

    for (final stop in stops.skip(1)) {
      final distance = distanceMeters(position, stop.position);

      if (distance < nearestDistance) {
        nearest = stop;
        nearestDistance = distance;
      }
    }

    return nearest;
  }

  double distanceMeters(LatLng a, LatLng b) {
    const earthRadiusMeters = 6371000.0;

    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);
    final deltaLat = _toRadians(b.latitude - a.latitude);
    final deltaLon = _toRadians(b.longitude - a.longitude);

    final sinLat = math.sin(deltaLat / 2);
    final sinLon = math.sin(deltaLon / 2);

    final haversine =
        (sinLat * sinLat) + math.cos(lat1) * math.cos(lat2) * (sinLon * sinLon);

    final centralAngle =
        2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));

    return earthRadiusMeters * centralAngle;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
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
