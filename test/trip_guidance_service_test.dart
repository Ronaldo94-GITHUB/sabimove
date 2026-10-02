import 'package:flutter_test/flutter_test.dart';
import 'package:sabimove/models/trip_guidance_step.dart';
import 'package:sabimove/services/trip_guidance_service.dart';
import 'package:sabimove/services/trip_planner_service.dart';

void main() {
  const planner = TripPlannerService();
  const guidance = TripGuidanceService();

  test('cria acompanhamento para viagem direta', () {
    final plan = planner.findPlan(
      originStopId: 'L01-P01',
      destinationStopId: 'L01-P03',
    );

    if (plan == null) {
      fail('Era esperada uma rota direta valida.');
    }

    final steps = guidance.buildSteps(plan);

    expect(steps, isNotEmpty);
    expect(steps.first.type, TripGuidanceStepType.board);
    expect(steps.first.instruction, contains('Linha 01'));
    expect(steps.last.type, TripGuidanceStepType.arrive);
    expect(steps.last.instruction, contains('Ponto Bairro'));
    expect(
      steps.where((step) => step.type == TripGuidanceStepType.walkTransfer),
      isEmpty,
    );
  });

  test('cria alerta de baldeacao em viagem com transferencia', () {
    final plan = planner.findPlan(
      originStopId: 'L03-P01',
      destinationStopId: 'L01-P03',
    );

    if (plan == null) {
      fail('Era esperada uma rota com baldeacao valida.');
    }

    expect(plan.transferCount, 1);

    final steps = guidance.buildSteps(plan);

    expect(
      steps.any((step) => step.type == TripGuidanceStepType.walkTransfer),
      isTrue,
    );

    expect(
      steps.where((step) => step.type == TripGuidanceStepType.board).length,
      2,
    );

    expect(steps.last.type, TripGuidanceStepType.arrive);
  });

  test('etapas seguem sequencia de paradas da linha', () {
    final plan = planner.findPlan(
      originStopId: 'L01-P01',
      destinationStopId: 'L01-P03',
    );

    if (plan == null) {
      fail('Era esperada uma rota valida para testar as etapas.');
    }

    final steps = guidance.buildSteps(plan);

    expect(steps[1].instruction, 'Ponto Intermediário');
    expect(steps.last.instruction, contains('Ponto Bairro'));
  });
}
