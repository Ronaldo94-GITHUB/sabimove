import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sabimove/models/trip_preference.dart';
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
    expect(plan.transferWalkingDistanceMeters, 0);
  });

  test('findDirectPlan continua restrito a viagem direta', () {
    final plan = planner.findDirectPlan(
      originStopId: 'L01-P01',
      destinationStopId: 'L02-P03',
    );

    expect(plan, isNull);
  });

  test('encontra multiplas alternativas com uma baldeacao', () {
    final plans = planner.findPlans(
      originStopId: 'L01-P01',
      destinationStopId: 'L02-P03',
      maxResults: 3,
    );

    expect(plans, hasLength(3));
    expect(plans.every((plan) => plan.transferCount == 1), isTrue);
  });

  test('prioridade mais rapida escolhe menor tempo total', () {
    final plans = planner.findPlans(
      originStopId: 'L01-P01',
      destinationStopId: 'L02-P03',
      preference: TripPreference.fastest,
      maxResults: 3,
    );

    expect(plans, isNotEmpty);
    expect(plans.first.estimatedMinutes, 28);
    expect(plans.first.transfers.first.fromStop.id, 'L01-P02');
    expect(plans.first.transfers.first.toStop.id, 'L02-P02');
  });

  test('prioridade menos caminhada escolhe conexao mais curta', () {
    final plans = planner.findPlans(
      originStopId: 'L01-P01',
      destinationStopId: 'L02-P03',
      preference: TripPreference.lessWalking,
      maxResults: 3,
    );

    expect(plans, isNotEmpty);
    expect(plans.first.transfers.first.fromStop.id, 'L01-P02');
    expect(plans.first.transfers.first.toStop.id, 'L02-P01');
    expect(plans.first.estimatedMinutes, 37);
    expect(
      plans.first.transferWalkingDistanceMeters,
      lessThan(plans[1].transferWalkingDistanceMeters),
    );
  });

  test('prioridade menos baldeacoes preserva viagem direta', () {
    final plans = planner.findPlans(
      originStopId: 'L01-P01',
      destinationStopId: 'L01-P03',
      preference: TripPreference.fewerTransfers,
      maxResults: 3,
    );

    expect(plans, hasLength(1));
    expect(plans.first.transferCount, 0);
    expect(plans.first.isDirect, isTrue);
  });

  test('respeita limite de alternativas', () {
    final plans = planner.findPlans(
      originStopId: 'L01-P01',
      destinationStopId: 'L02-P03',
      maxResults: 2,
    );

    expect(plans, hasLength(2));
  });

  test('mantem baldeacao da Linha 03 para a Linha 01', () {
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
