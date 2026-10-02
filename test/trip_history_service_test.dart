import 'package:flutter_test/flutter_test.dart';
import 'package:sabimove/models/trip_preference.dart';
import 'package:sabimove/services/trip_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('registra viagem e persiste no historico', () async {
    final service = TripHistoryService();

    await service.recordTrip(
      originStopId: 'L01-P01',
      destinationStopId: 'L02-P03',
      preference: TripPreference.fastest,
      planSignature: 'rota-a',
      now: DateTime.utc(2026, 10, 2, 8),
    );

    final trips = await service.loadTrips();

    expect(trips, hasLength(1));
    expect(trips.first.originStopId, 'L01-P01');
    expect(trips.first.destinationStopId, 'L02-P03');
    expect(trips.first.preference, TripPreference.fastest);
    expect(trips.first.isFavorite, isFalse);
  });

  test('replanejar mesma rota atualiza sem duplicar', () async {
    final service = TripHistoryService();

    await service.recordTrip(
      originStopId: 'L01-P01',
      destinationStopId: 'L02-P03',
      preference: TripPreference.fastest,
      planSignature: 'rota-a',
      now: DateTime.utc(2026, 10, 2, 8),
    );

    await service.recordTrip(
      originStopId: 'L01-P01',
      destinationStopId: 'L02-P03',
      preference: TripPreference.fastest,
      planSignature: 'rota-a',
      now: DateTime.utc(2026, 10, 2, 9),
    );

    final trips = await service.loadTrips();

    expect(trips, hasLength(1));
    expect(trips.first.updatedAt, DateTime.utc(2026, 10, 2, 9));
  });

  test('salva favorito e mantem ao limpar historico', () async {
    final service = TripHistoryService();

    await service.saveFavorite(
      originStopId: 'L03-P01',
      destinationStopId: 'L01-P03',
      preference: TripPreference.lessWalking,
      planSignature: 'favorita',
      now: DateTime.utc(2026, 10, 2, 8),
    );

    await service.recordTrip(
      originStopId: 'L01-P01',
      destinationStopId: 'L01-P03',
      preference: TripPreference.fastest,
      planSignature: 'recente',
      now: DateTime.utc(2026, 10, 2, 9),
    );

    final remaining = await service.clearHistoryKeepFavorites();

    expect(remaining, hasLength(1));
    expect(remaining.first.isFavorite, isTrue);
    expect(remaining.first.planSignature, 'favorita');
  });

  test('alterna favorito', () async {
    final service = TripHistoryService();

    final trips = await service.recordTrip(
      originStopId: 'L01-P01',
      destinationStopId: 'L01-P03',
      preference: TripPreference.fastest,
      planSignature: 'rota-a',
      now: DateTime.utc(2026, 10, 2, 8),
    );

    final updated = await service.toggleFavorite(trips.first.storageKey);

    expect(updated.first.isFavorite, isTrue);

    final reverted = await service.toggleFavorite(updated.first.storageKey);

    expect(reverted.first.isFavorite, isFalse);
  });

  test('remove viagem salva', () async {
    final service = TripHistoryService();

    final trips = await service.recordTrip(
      originStopId: 'L01-P01',
      destinationStopId: 'L01-P03',
      preference: TripPreference.fastest,
      planSignature: 'rota-a',
    );

    final updated = await service.removeTrip(trips.first.storageKey);

    expect(updated, isEmpty);
    expect(await service.loadTrips(), isEmpty);
  });
}
