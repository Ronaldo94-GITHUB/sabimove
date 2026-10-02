import '../models/trip_guidance_step.dart';
import '../models/trip_leg.dart';
import '../models/trip_plan.dart';
import '../models/transit_stop.dart';

class TripGuidanceService {
  const TripGuidanceService();

  List<TripGuidanceStep> buildSteps(TripPlan plan) {
    final steps = <TripGuidanceStep>[];

    for (var legIndex = 0; legIndex < plan.legs.length; legIndex++) {
      final leg = plan.legs[legIndex];

      steps.add(
        TripGuidanceStep(
          type: TripGuidanceStepType.board,
          title: legIndex == 0 ? 'Embarque' : 'Novo embarque',
          instruction: 'Embarque na ${leg.line.name} em ${leg.origin.name}.',
          detail: leg.line.direction,
          position: leg.origin.position,
          legIndex: legIndex,
        ),
      );

      final legStops = _stopsAfterOrigin(leg);

      for (final stop in legStops) {
        final isLegDestination = stop.id == leg.destination.id;
        final isFinalLeg = legIndex == plan.legs.length - 1;

        if (isLegDestination && isFinalLeg) {
          steps.add(
            TripGuidanceStep(
              type: TripGuidanceStepType.arrive,
              title: 'Destino alcançado',
              instruction: 'Desembarque em ${stop.name}.',
              detail: 'Fim da viagem simulada.',
              position: stop.position,
              legIndex: legIndex,
            ),
          );
          continue;
        }

        if (isLegDestination) {
          steps.add(
            TripGuidanceStep(
              type: TripGuidanceStepType.ride,
              title: 'Prepare-se para a baldeação',
              instruction: 'Desça em ${stop.name}.',
              detail: 'A próxima etapa será a conexão entre as linhas.',
              position: stop.position,
              legIndex: legIndex,
            ),
          );
          continue;
        }

        steps.add(
          TripGuidanceStep(
            type: TripGuidanceStepType.ride,
            title: 'Próxima parada',
            instruction: stop.name,
            detail: '${leg.line.name} • ${leg.line.direction}',
            position: stop.position,
            legIndex: legIndex,
          ),
        );
      }

      if (legIndex < plan.transfers.length) {
        final transfer = plan.transfers[legIndex];

        steps.add(
          TripGuidanceStep(
            type: TripGuidanceStepType.walkTransfer,
            title: 'Baldeação a pé',
            instruction:
                'Caminhe de ${transfer.fromStop.name} até ${transfer.toStop.name}.',
            detail:
                '${transfer.walkingDistanceMeters.round()} m • '
                '${transfer.walkingMinutes} min a pé + '
                '${transfer.bufferMinutes} min de integração',
            position: transfer.toStop.position,
            legIndex: legIndex,
          ),
        );
      }
    }

    return steps;
  }

  List<TransitStop> _stopsAfterOrigin(TripLeg leg) {
    final stops =
        leg.line.stops
            .where(
              (stop) =>
                  stop.sequence > leg.origin.sequence &&
                  stop.sequence <= leg.destination.sequence,
            )
            .toList()
          ..sort((a, b) => a.sequence.compareTo(b.sequence));

    return stops;
  }
}
