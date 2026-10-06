class Space {
  final String id;
  final String name;
  final String location;
  final double rating;
  final double pricePerDay;
  final int availableSeats;
  final List<String> amenities;

  Space({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.pricePerDay,
    required this.availableSeats,
    required this.amenities,
  });
}