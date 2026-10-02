import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../data/mock_lines.dart';
import '../models/transit_line.dart';
import '../models/transit_stop.dart';
import '../models/trip_leg.dart';
import '../models/trip_plan.dart';
import '../models/trip_transfer.dart';

class TripPlannerService {
  const TripPlannerService();

  static const double maxTransferWalkMeters = 600;
  static const double walkingSpeedMetersPerMinute = 75;
  static const int transferBufferMinutes = 3;

  TripPlan? findPlan({
    required String originStopId,
    required String destinationStopId,
  }) {
    final direct = findDirectPlan(
      originStopId: originStopId,
      destinationStopId: destinationStopId,
    );

    if (direct != null) {
      return direct;
    }

    return _findOneTransferPlan(
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

    final line = _lineContainingStop(originStopId);

    if (line == null || !_lineContainsStop(line, destinationStopId)) {
      return null;
    }

    final origin = _stopOnLine(line, originStopId);
    final destination = _stopOnLine(line, destinationStopId);

    if (origin == null || destination == null) {
      return null;
    }

    final leg = _buildLeg(line: line, origin: origin, destination: destination);

    if (leg == null) {
      return null;
    }

    return TripPlan(legs: [leg], estimatedMinutes: leg.estimatedMinutes);
  }

  TripPlan? _findOneTransferPlan({
    required String originStopId,
    required String destinationStopId,
  }) {
    final firstLine = _lineContainingStop(originStopId);
    final secondLine = _lineContainingStop(destinationStopId);

    if (firstLine == null ||
        secondLine == null ||
        firstLine.id == secondLine.id) {
      return null;
    }

    final origin = _stopOnLine(firstLine, originStopId);
    final destination = _stopOnLine(secondLine, destinationStopId);

    if (origin == null || destination == null) {
      return null;
    }

    TripPlan? bestPlan;
    double? bestTransferDistance;

    for (final firstTransferStop in firstLine.stops) {
      final firstLeg = _buildLeg(
        line: firstLine,
        origin: origin,
        destination: firstTransferStop,
      );

      if (firstLeg == null) {
        continue;
      }

      for (final secondTransferStop in secondLine.stops) {
        final secondLeg = _buildLeg(
          line: secondLine,
          origin: secondTransferStop,
          destination: destination,
        );

        if (secondLeg == null) {
          continue;
        }

        final walkingDistance = distanceMeters(
          firstTransferStop.position,
          secondTransferStop.position,
        );

        if (walkingDistance > maxTransferWalkMeters) {
          continue;
        }

        var walkingMinutes = (walkingDistance / walkingSpeedMetersPerMinute)
            .ceil();

        if (walkingMinutes < 1) {
          walkingMinutes = 1;
        }

        final transfer = TripTransfer(
          fromStop: firstTransferStop,
          toStop: secondTransferStop,
          walkingDistanceMeters: walkingDistance,
          walkingMinutes: walkingMinutes,
          bufferMinutes: transferBufferMinutes,
        );

        final totalMinutes =
            firstLeg.estimatedMinutes +
            transfer.estimatedMinutes +
            secondLeg.estimatedMinutes;

        final candidate = TripPlan(
          legs: [firstLeg, secondLeg],
          transfers: [transfer],
          estimatedMinutes: totalMinutes,
        );

        if (bestPlan == null ||
            totalMinutes < bestPlan.estimatedMinutes ||
            (totalMinutes == bestPlan.estimatedMinutes &&
                (bestTransferDistance == null ||
                    walkingDistance < bestTransferDistance))) {
          bestPlan = candidate;
          bestTransferDistance = walkingDistance;
        }
      }
    }

    return bestPlan;
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

  TransitLine? _lineContainingStop(String stopId) {
    for (final line in mockLines) {
      if (_lineContainsStop(line, stopId)) {
        return line;
      }
    }

    return null;
  }

  bool _lineContainsStop(TransitLine line, String stopId) {
    return line.stops.any((stop) => stop.id == stopId);
  }

  TransitStop? _stopOnLine(TransitLine line, String stopId) {
    for (final stop in line.stops) {
      if (stop.id == stopId) {
        return stop;
      }
    }

    return null;
  }

  TripLeg? _buildLeg({
    required TransitLine line,
    required TransitStop origin,
    required TransitStop destination,
  }) {
    if (destination.sequence <= origin.sequence) {
      return null;
    }

    final stopsTraveled = destination.sequence - origin.sequence;

    var estimatedMinutes = 1;

    if (line.stops.length > 1) {
      const simulatedFullRouteMinutes = 18.0;
      final fraction = stopsTraveled / (line.stops.length - 1);
      estimatedMinutes = (fraction * simulatedFullRouteMinutes).ceil();

      if (estimatedMinutes < 1) {
        estimatedMinutes = 1;
      }
    }

    return TripLeg(
      line: line,
      origin: origin,
      destination: destination,
      routeSegment: _routeSegment(
        line: line,
        origin: origin,
        destination: destination,
      ),
      stopsTraveled: stopsTraveled,
      estimatedMinutes: estimatedMinutes,
    );
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
