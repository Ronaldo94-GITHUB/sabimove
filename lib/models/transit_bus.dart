class TransitBus {
  final String id;
  final String lineId;
  final String vehicleNumber;
  final double progress;
  final int nextStopMinutes;

  const TransitBus({
    required this.id,
    required this.lineId,
    required this.vehicleNumber,
    required this.progress,
    required this.nextStopMinutes,
  });

  TransitBus copyWith({
    String? id,
    String? lineId,
    String? vehicleNumber,
    double? progress,
    int? nextStopMinutes,
  }) {
    return TransitBus(
      id: id ?? this.id,
      lineId: lineId ?? this.lineId,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      progress: progress ?? this.progress,
      nextStopMinutes: nextStopMinutes ?? this.nextStopMinutes,
    );
  }
}
