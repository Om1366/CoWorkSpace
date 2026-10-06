class Seat {
  final String id;
  final int number;
  bool isOccupied;

  Seat({
    required this.id,
    required this.number,
    this.isOccupied = false,
  });
}