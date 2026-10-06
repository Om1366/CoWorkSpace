class Booking {
  final String id;
  final String spaceId;
  final int seatNumber;
  final DateTime date;
  final double basePrice;
  final double convenienceFee;
  final double tax;
  String status;

  Booking({
    required this.id,
    required this.spaceId,
    required this.seatNumber,
    required this.date,
    required this.basePrice,
    required this.convenienceFee,
    required this.tax,
    this.status = 'Pending',
  });

  double get totalPrice {
    return basePrice + convenienceFee + tax;
  }
}