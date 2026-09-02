import 'package:latlong2/latlong.dart';

class TransitStop {
  final String id;
  final String name;
  final LatLng position;
  final int sequence;

  const TransitStop({
    required this.id,
    required this.name,
    required this.position,
    required this.sequence,
  });
}
