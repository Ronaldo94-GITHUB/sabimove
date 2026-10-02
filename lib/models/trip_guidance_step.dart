import 'package:latlong2/latlong.dart';

enum TripGuidanceStepType { board, ride, walkTransfer, arrive }

class TripGuidanceStep {
  final TripGuidanceStepType type;
  final String title;
  final String instruction;
  final String detail;
  final LatLng position;
  final int legIndex;

  const TripGuidanceStep({
    required this.type,
    required this.title,
    required this.instruction,
    required this.detail,
    required this.position,
    required this.legIndex,
  });
}
