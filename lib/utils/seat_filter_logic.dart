import '../models/bus_model.dart';
import '../models/seat_model.dart';

class SeatFilterLogic {
  static int getSeatAvailabilityCount({
    required String seatId,
    required String layout,
    required List<BusModel> allBuses,
  }) {
    return allBuses
        .where((bus) => bus.layout == layout)
        .where((bus) => bus.availableSeats.contains(seatId))
        .length;
  }

  static List<BusModel> filterBySelectedSeats({
    required List<String> selectedSeats,
    required String layout,
    required List<BusModel> allBuses,
  }) {
    if (selectedSeats.isEmpty) return [];
    return allBuses
        .where((bus) => bus.layout == layout)
        .where(
          (bus) => selectedSeats.every(
            (seat) => bus.availableSeats.contains(seat),
          ),
        )
        .toList();
  }

  static List<BusModel> filterByCount({
    required int count,
    required String layout,
    required List<BusModel> allBuses,
  }) {
    return allBuses
        .where((bus) => bus.layout == layout)
        .where((bus) => bus.availableSeats.length >= count)
        .toList();
  }

  static List<SeatModel> generateSeatGrid({
    required String layout,
    required List<BusModel> allBuses,
  }) {
    final List<SeatModel> seats = [];

    switch (layout) {
      case '2+1':
        for (int row = 1; row <= 10; row++) {
          for (final col in ['A', 'B', 'C']) {
            final id = '$row$col';
            seats.add(SeatModel(
              id: id,
              row: '$row',
              column: col,
              type: col == 'A'
                  ? 'window-left'
                  : col == 'C'
                      ? 'window-right'
                      : 'aisle',
              availableCount: getSeatAvailabilityCount(
                seatId: id,
                layout: layout,
                allBuses: allBuses,
              ),
            ));
          }
        }
        break;

      case '2+2':
        for (int row = 1; row <= 10; row++) {
          for (final col in ['A', 'B', 'C', 'D']) {
            final id = '$row$col';
            seats.add(SeatModel(
              id: id,
              row: '$row',
              column: col,
              type: (col == 'A' || col == 'D') ? 'window' : 'aisle',
              availableCount: getSeatAvailabilityCount(
                seatId: id,
                layout: layout,
                allBuses: allBuses,
              ),
            ));
          }
        }
        break;

      case 'Sleeper':
        for (int row = 1; row <= 7; row++) {
          for (final prefix in ['L', 'U']) {
            for (final col in ['A', 'B', 'C']) {
              final id = '$prefix$row$col';
              seats.add(SeatModel(
                id: id,
                row: '$row',
                column: col,
                type: prefix == 'L' ? 'lower' : 'upper',
                availableCount: getSeatAvailabilityCount(
                  seatId: id,
                  layout: layout,
                  allBuses: allBuses,
                ),
              ));
            }
          }
        }
        break;

      case 'Semi-Sleeper':
        for (int row = 1; row <= 10; row++) {
          for (final col in ['A', 'B', 'C', 'D']) {
            final id = '$row$col';
            seats.add(SeatModel(
              id: id,
              row: '$row',
              column: col,
              type: (col == 'A' || col == 'D') ? 'window' : 'aisle',
              availableCount: getSeatAvailabilityCount(
                seatId: id,
                layout: layout,
                allBuses: allBuses,
              ),
            ));
          }
        }
        break;
    }
    return seats;
  }
}
