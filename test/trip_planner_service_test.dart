import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sabimove/services/trip_planner_service.dart';

void main() {
  const planner = TripPlannerService();

  test('planeja viagem direta completa na Linha 01', () {
    final plan = planner.findPlan(
      originStopId: 'L01-P01',
      destinationStopId: 'L01-P03',
    );

    expect(plan, isNotNull);
    expect(plan!.isDirect, isTrue);
    expect(plan.legs, hasLength(1));
    expect(plan.line.id, '01');
    expect(plan.origin.id, 'L01-P01');
    expect(plan.destination.id, 'L01-P03');
    expect(plan.stopsTraveled, 2);
    expect(plan.estimatedMinutes, 18);
    expect(plan.routeSegment, isNotEmpty);
  });

  test('planeja trecho intermediario na Linha 01', () {
    final plan = planner.findPlan(
      originStopId: 'L01-P01',
      destinationStopId: 'L01-P02',
    );

    expect(plan, isNotNull);
    expect(plan!.estimatedMinutes, 9);
    expect(plan.stopsTraveled, 1);
    expect(plan.legs.single.estimatedMinutes, 9);
  });

  test('nao cria viagem no sentido inverso', () {
    final plan = planner.findPlan(
      originStopId: 'L01-P03',
      destinationStopId: 'L01-P01',
    );

    expect(plan, isNull);
  });

  test('nao cria viagem direta entre linhas diferentes', () {
    final plan = planner.findPlan(
      originStopId: 'L01-P01',
      destinationStopId: 'L02-P03',
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
