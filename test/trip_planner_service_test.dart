import 'package:flutter_test/flutter_test.dart';
import 'package:sabimove/services/trip_planner_service.dart';

void main() {
  const planner = TripPlannerService();

  test('planeja viagem direta completa na Linha 01', () {
    final plan = planner.findDirectPlan(
      originStopId: 'L01-P01',
      destinationStopId: 'L01-P03',
    );

    expect(plan, isNotNull);
    expect(plan!.line.id, '01');
    expect(plan.origin.id, 'L01-P01');
    expect(plan.destination.id, 'L01-P03');
    expect(plan.stopsTraveled, 2);
    expect(plan.estimatedMinutes, 18);
    expect(plan.routeSegment, isNotEmpty);
  });

  test('planeja trecho intermediario na Linha 01', () {
    final plan = planner.findDirectPlan(
      originStopId: 'L01-P01',
      destinationStopId: 'L01-P02',
    );

    expect(plan, isNotNull);
    expect(plan!.estimatedMinutes, 9);
    expect(plan.stopsTraveled, 1);
  });

  test('nao cria viagem no sentido inverso', () {
    final plan = planner.findDirectPlan(
      originStopId: 'L01-P03',
      destinationStopId: 'L01-P01',
    );

    expect(plan, isNull);
  });

  test('nao cria viagem direta entre linhas diferentes', () {
    final plan = planner.findDirectPlan(
      originStopId: 'L01-P01',
      destinationStopId: 'L02-P03',
    );

    expect(plan, isNull);
  });
}
