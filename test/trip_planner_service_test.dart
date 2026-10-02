import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sabimove/services/trip_planner_service.dart';

void main() {
  const planner = TripPlannerService();

  test('mantem viagem direta quando existe', () {
    final plan = planner.findPlan(
      originStopId: 'L01-P01',
      destinationStopId: 'L01-P03',
    );

    expect(plan, isNotNull);
    expect(plan!.isDirect, isTrue);
    expect(plan.transferCount, 0);
    expect(plan.transfers, isEmpty);
    expect(plan.legs, hasLength(1));
    expect(plan.line.id, '01');
    expect(plan.origin.id, 'L01-P01');
    expect(plan.destination.id, 'L01-P03');
    expect(plan.stopsTraveled, 2);
    expect(plan.estimatedMinutes, 18);
  });

  test('findDirectPlan continua restrito a viagem direta', () {
    final plan = planner.findDirectPlan(
      originStopId: 'L01-P01',
      destinationStopId: 'L02-P03',
    );

    expect(plan, isNull);
  });

  test('planeja uma baldeacao da Linha 01 para a Linha 02', () {
    final plan = planner.findPlan(
      originStopId: 'L01-P01',
      destinationStopId: 'L02-P03',
    );

    expect(plan, isNotNull);
    expect(plan!.isDirect, isFalse);
    expect(plan.transferCount, 1);
    expect(plan.legs, hasLength(2));
    expect(plan.transfers, hasLength(1));
    expect(plan.legs.first.line.id, '01');
    expect(plan.legs.last.line.id, '02');
    expect(plan.transfers.first.fromStop.id, 'L01-P02');
    expect(plan.transfers.first.toStop.id, 'L02-P02');
    expect(
      plan.transfers.first.walkingDistanceMeters,
      lessThanOrEqualTo(TripPlannerService.maxTransferWalkMeters),
    );
    expect(plan.estimatedMinutes, 28);
  });

  test('planeja uma baldeacao da Linha 03 para a Linha 01', () {
    final plan = planner.findPlan(
      originStopId: 'L03-P01',
      destinationStopId: 'L01-P03',
    );

    expect(plan, isNotNull);
    expect(plan!.transferCount, 1);
    expect(plan.legs.first.line.id, '03');
    expect(plan.legs.last.line.id, '01');
    expect(plan.transfers.first.fromStop.id, 'L03-P02');
    expect(plan.transfers.first.toStop.id, 'L01-P02');
    expect(plan.estimatedMinutes, 26);
  });

  test('nao cria rota quando a direcao torna a conexao impossivel', () {
    final plan = planner.findPlan(
      originStopId: 'L01-P03',
      destinationStopId: 'L02-P01',
    );

    expect(plan, isNull);
  });

  test('encontra a parada mais proxima da localizacao', () {
    const position = LatLng(-22.4710, -48.9940);

    final stop = planner.nearestStopTo(position);
    final distance = planner.distanceMeters(position, stop.position);

    expect(stop.id, 'L01-P01');
    expect(distance, lessThan(1));
  });

  test('calcula distancia positiva entre pontos diferentes', () {
    const origin = LatLng(-22.4710, -48.9940);
    const destination = LatLng(-22.4694, -48.9875);

    final distance = planner.distanceMeters(origin, destination);

    expect(distance, greaterThan(0));
  });
}
