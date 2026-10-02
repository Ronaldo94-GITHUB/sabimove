import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../data/mock_lines.dart';
import '../models/transit_line.dart';
import '../models/transit_stop.dart';
import '../models/trip_leg.dart';
import '../models/trip_plan.dart';
import '../models/trip_preference.dart';
import '../models/trip_transfer.dart';

class TripPlannerService {
  const TripPlannerService();

  static const double maxTransferWalkMeters = 600;
  static const double walkingSpeedMetersPerMinute = 75;
  static const int transferBufferMinutes = 3;

  TripPlan? findPlan({
    required String originStopId,
    required String destinationStopId,
    TripPreference preference = TripPreference.fastest,
  }) {
    final plans = findPlans(
      originStopId: originStopId,
      destinationStopId: destinationStopId,
      preference: preference,
      maxResults: 1,
    );

    return plans.isEmpty ? null : plans.first;
  }

  List<TripPlan> findPlans({
    required String originStopId,
    required String destinationStopId,
    TripPreference preference = TripPreference.fastest,
    int maxResults = 3,
  }) {
    if (originStopId == destinationStopId || maxResults <= 0) {
      return const <TripPlan>[];
    }

    final candidates = <TripPlan>[];

    final direct = findDirectPlan(
      originStopId: originStopId,
      destinationStopId: destinationStopId,
    );

    if (direct != null) {
      candidates.add(direct);
    } else {
      candidates.addAll(
        _findOneTransferPlans(
          originStopId: originStopId,
          destinationStopId: destinationStopId,
        ),
      );
    }

    candidates.sort((a, b) => _comparePlans(a, b, preference));

    if (candidates.length <= maxResults) {
      return candidates;
    }

    return candidates.take(maxResults).toList();
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

  List<TripPlan> _findOneTransferPlans({
    required String originStopId,
    required String destinationStopId,
  }) {
    final firstLine = _lineContainingStop(originStopId);
    final secondLine = _lineContainingStop(destinationStopId);

    if (firstLine == null ||
        secondLine == null ||
        firstLine.id == secondLine.id) {
      return const <TripPlan>[];
    }

    final origin = _stopOnLine(firstLine, originStopId);
    final destination = _stopOnLine(secondLine, destinationStopId);

    if (origin == null || destination == null) {
      return const <TripPlan>[];
    }

    final candidates = <TripPlan>[];

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

        candidates.add(
          TripPlan(
            legs: [firstLeg, secondLeg],
            transfers: [transfer],
            estimatedMinutes: totalMinutes,
          ),
        );
      }
    }

    return candidates;
  }

  int _comparePlans(TripPlan a, TripPlan b, TripPreference preference) {
    switch (preference) {
      case TripPreference.fastest:
        return _compareFastest(a, b);
      case TripPreference.lessWalking:
        return _compareLessWalking(a, b);
      case TripPreference.fewerTransfers:
        return _compareFewerTransfers(a, b);
    }
  }

  int _compareFastest(TripPlan a, TripPlan b) {
    final timeComparison = a.estimatedMinutes.compareTo(b.estimatedMinutes);

    if (timeComparison != 0) {
      return timeComparison;
    }

    final walkingComparison = a.transferWalkingDistanceMeters.compareTo(
      b.transferWalkingDistanceMeters,
    );

    if (walkingComparison != 0) {
      return walkingComparison;
    }

    return a.transferCount.compareTo(b.transferCount);
  }

  int _compareLessWalking(TripPlan a, TripPlan b) {
    final walkingComparison = a.transferWalkingDistanceMeters.compareTo(
      b.transferWalkingDistanceMeters,
    );

    if (walkingComparison != 0) {
      return walkingComparison;
    }

    final timeComparison = a.estimatedMinutes.compareTo(b.estimatedMinutes);

    if (timeComparison != 0) {
      return timeComparison;
    }

    return a.transferCount.compareTo(b.transferCount);
  }

  int _compareFewerTransfers(TripPlan a, TripPlan b) {
    final transferComparison = a.transferCount.compareTo(b.transferCount);

    if (transferComparison != 0) {
      return transferComparison;
    }

    final timeComparison = a.estimatedMinutes.compareTo(b.estimatedMinutes);

    if (timeComparison != 0) {
      return timeComparison;
    }

    return a.transferWalkingDistanceMeters.compareTo(
      b.transferWalkingDistanceMeters,
    );
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
