import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_trip.dart';
import '../models/trip_preference.dart';

class TripHistoryService {
  static const String _storageKey = 'sabimove.trip_history_v14';
  static const int maxRecentTrips = 20;

  Future<List<SavedTrip>> loadTrips() async {
    final preferences = await SharedPreferences.getInstance();

    final rawItems = preferences.getStringList(_storageKey) ?? const <String>[];

    final trips = rawItems
        .map(SavedTrip.tryFromJson)
        .whereType<SavedTrip>()
        .toList();

    trips.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return trips;
  }

  Future<List<SavedTrip>> recordTrip({
    required String originStopId,
    required String destinationStopId,
    required TripPreference preference,
    required String planSignature,
    DateTime? now,
  }) async {
    final trips = await loadTrips();

    final candidate = SavedTrip(
      originStopId: originStopId,
      destinationStopId: destinationStopId,
      preference: preference,
      planSignature: planSignature,
      updatedAt: now ?? DateTime.now(),
      isFavorite: false,
    );

    final existing = _findByKey(trips, candidate.storageKey);

    final updated = candidate.copyWith(
      isFavorite: existing?.isFavorite ?? false,
    );

    final merged = <SavedTrip>[
      updated,
      ...trips.where((trip) => trip.storageKey != updated.storageKey),
    ];

    final trimmed = _trimRecent(merged);

    await _save(trimmed);

    return trimmed;
  }

  Future<List<SavedTrip>> saveFavorite({
    required String originStopId,
    required String destinationStopId,
    required TripPreference preference,
    required String planSignature,
    DateTime? now,
  }) async {
    final trips = await loadTrips();

    final favorite = SavedTrip(
      originStopId: originStopId,
      destinationStopId: destinationStopId,
      preference: preference,
      planSignature: planSignature,
      updatedAt: now ?? DateTime.now(),
      isFavorite: true,
    );

    final merged = <SavedTrip>[
      favorite,
      ...trips.where((trip) => trip.storageKey != favorite.storageKey),
    ];

    final trimmed = _trimRecent(merged);

    await _save(trimmed);

    return trimmed;
  }

  Future<List<SavedTrip>> toggleFavorite(String storageKey) async {
    final trips = await loadTrips();

    final updated = trips
        .map(
          (trip) => trip.storageKey == storageKey
              ? trip.copyWith(
                  isFavorite: !trip.isFavorite,
                  updatedAt: DateTime.now(),
                )
              : trip,
        )
        .toList();

    updated.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final trimmed = _trimRecent(updated);

    await _save(trimmed);

    return trimmed;
  }

  Future<List<SavedTrip>> removeTrip(String storageKey) async {
    final trips = await loadTrips();

    final updated = trips
        .where((trip) => trip.storageKey != storageKey)
        .toList();

    await _save(updated);

    return updated;
  }

  Future<List<SavedTrip>> clearHistoryKeepFavorites() async {
    final trips = await loadTrips();

    final favorites = trips.where((trip) => trip.isFavorite).toList();

    await _save(favorites);

    return favorites;
  }

  SavedTrip? _findByKey(List<SavedTrip> trips, String storageKey) {
    for (final trip in trips) {
      if (trip.storageKey == storageKey) {
        return trip;
      }
    }

    return null;
  }

  List<SavedTrip> _trimRecent(List<SavedTrip> trips) {
    final sorted = [...trips]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    var recentCount = 0;

    final result = <SavedTrip>[];

    for (final trip in sorted) {
      if (trip.isFavorite) {
        result.add(trip);
        continue;
      }

      if (recentCount < maxRecentTrips) {
        result.add(trip);
        recentCount++;
      }
    }

    return result;
  }

  Future<void> _save(List<SavedTrip> trips) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setStringList(
      _storageKey,
      trips.map((trip) => trip.toJson()).toList(),
    );
  }
}
