import '../models/transit_bus.dart';

const mockBuses = <TransitBus>[
  TransitBus(
    id: 'bus-01-101',
    lineId: '01',
    vehicleNumber: '101',
    progress: 0.15,
    nextStopMinutes: 3,
  ),
  TransitBus(
    id: 'bus-01-102',
    lineId: '01',
    vehicleNumber: '102',
    progress: 0.52,
    nextStopMinutes: 6,
  ),
  TransitBus(
    id: 'bus-01-103',
    lineId: '01',
    vehicleNumber: '103',
    progress: 0.82,
    nextStopMinutes: 2,
  ),

  TransitBus(
    id: 'bus-02-201',
    lineId: '02',
    vehicleNumber: '201',
    progress: 0.20,
    nextStopMinutes: 4,
  ),
  TransitBus(
    id: 'bus-02-202',
    lineId: '02',
    vehicleNumber: '202',
    progress: 0.58,
    nextStopMinutes: 5,
  ),
  TransitBus(
    id: 'bus-02-203',
    lineId: '02',
    vehicleNumber: '203',
    progress: 0.88,
    nextStopMinutes: 2,
  ),

  TransitBus(
    id: 'bus-03-301',
    lineId: '03',
    vehicleNumber: '301',
    progress: 0.10,
    nextStopMinutes: 5,
  ),
  TransitBus(
    id: 'bus-03-302',
    lineId: '03',
    vehicleNumber: '302',
    progress: 0.48,
    nextStopMinutes: 3,
  ),
  TransitBus(
    id: 'bus-03-303',
    lineId: '03',
    vehicleNumber: '303',
    progress: 0.76,
    nextStopMinutes: 4,
  ),
];
