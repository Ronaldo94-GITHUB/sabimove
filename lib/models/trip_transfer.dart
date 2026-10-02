import 'transit_stop.dart';

class TripTransfer {
  final TransitStop fromStop;
  final TransitStop toStop;
  final double walkingDistanceMeters;
  final int walkingMinutes;
  final int bufferMinutes;

  const TripTransfer({
    required this.fromStop,
    required this.toStop,
    required this.walkingDistanceMeters,
    required this.walkingMinutes,
    required this.bufferMinutes,
  });

  int get estimatedMinutes => walkingMinutes + bufferMinutes;
}
