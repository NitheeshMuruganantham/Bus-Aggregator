class SeatModel {
  final String id;
  final String row;
  final String column;
  final String type;
  final int availableCount;
  bool isSelected;

  SeatModel({
    required this.id,
    required this.row,
    required this.column,
    required this.type,
    required this.availableCount,
    this.isSelected = false,
  });
}
