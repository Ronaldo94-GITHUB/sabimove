import 'dart:convert';

import 'trip_preference.dart';

class SavedTrip {
  final String originStopId;
  final String destinationStopId;
  final TripPreference preference;
  final String planSignature;
  final DateTime updatedAt;
  final bool isFavorite;

  const SavedTrip({
    required this.originStopId,
    required this.destinationStopId,
    required this.preference,
    required this.planSignature,
    required this.updatedAt,
    required this.isFavorite,
  });

  String get storageKey {
    return '$originStopId|$destinationStopId|${preference.name}|$planSignature';
  }

  SavedTrip copyWith({DateTime? updatedAt, bool? isFavorite}) {
    return SavedTrip(
      originStopId: originStopId,
      destinationStopId: destinationStopId,
      preference: preference,
      planSignature: planSignature,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, Object> toMap() {
    return <String, Object>{
      'originStopId': originStopId,
      'destinationStopId': destinationStopId,
      'preference': preference.name,
      'planSignature': planSignature,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  static SavedTrip? tryFromJson(String source) {
    try {
      final decoded = jsonDecode(source);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final originStopId = decoded['originStopId'];
      final destinationStopId = decoded['destinationStopId'];
      final preferenceName = decoded['preference'];
      final planSignature = decoded['planSignature'];
      final updatedAtText = decoded['updatedAt'];
      final isFavorite = decoded['isFavorite'];

      if (originStopId is! String ||
          destinationStopId is! String ||
          preferenceName is! String ||
          planSignature is! String ||
          updatedAtText is! String ||
          isFavorite is! bool) {
        return null;
      }

      final updatedAt = DateTime.tryParse(updatedAtText);

      if (updatedAt == null) {
        return null;
      }

      final preference = TripPreference.values.firstWhere(
        (item) => item.name == preferenceName,
        orElse: () => TripPreference.fastest,
      );

      return SavedTrip(
        originStopId: originStopId,
        destinationStopId: destinationStopId,
        preference: preference,
        planSignature: planSignature,
        updatedAt: updatedAt,
        isFavorite: isFavorite,
      );
    } catch (_) {
      return null;
    }
  }
}
