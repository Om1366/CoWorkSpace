import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/space.dart';
import '../models/seat.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ------------------------------------------------------------
  // GET ALL COWORKING SPACES
  // ------------------------------------------------------------

  Future<List<Space>> getSpaces() async {
    final snapshot = await _firestore.collection('spaces').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return Space(
        id: doc.id,
        name: data['name'] ?? '',
        location: data['location'] ?? '',
        rating: (data['rating'] ?? 0).toDouble(),
        pricePerDay: (data['pricePerDay'] ?? 0).toDouble(),
        availableSeats: data['availableSeats'] ?? 0,
        amenities: List<String>.from(data['amenities'] ?? []),
      );
    }).toList();
  }

  // ------------------------------------------------------------
  // GET SEATS FOR A SPACE
  // ------------------------------------------------------------

  Future<List<Seat>> getSeats(String spaceId) async {
    final seatsRef = _firestore
        .collection('spaces')
        .doc(spaceId)
        .collection('seats');

    final snapshot = await seatsRef.get();

    // If seats don't exist yet, automatically create 12 seats.
    if (snapshot.docs.isEmpty) {
      final batch = _firestore.batch();

      for (int i = 1; i <= 12; i++) {
        final seatRef = seatsRef.doc('S$i');

        batch.set(seatRef, {
          'number': i,

          // Demo occupied seats.
          'isOccupied': i == 3 || i == 8,
        });
      }

      await batch.commit();

      final newSnapshot = await seatsRef.get();

      return newSnapshot.docs.map((doc) {
        final data = doc.data();

        return Seat(
          id: doc.id,
          number: data['number'] ?? 0,
          isOccupied: data['isOccupied'] ?? false,
        );
      }).toList();
    }

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return Seat(
        id: doc.id,
        number: data['number'] ?? 0,
        isOccupied: data['isOccupied'] ?? false,
      );
    }).toList();
  }

  // ------------------------------------------------------------
  // GET ONE SPACE BY ID
  // ------------------------------------------------------------

  Future<Space?> getSpaceById(String spaceId) async {
    final doc = await _firestore.collection('spaces').doc(spaceId).get();

    if (!doc.exists) {
      return null;
    }

    final data = doc.data();

    if (data == null) {
      return null;
    }

    return Space(
      id: doc.id,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      pricePerDay: (data['pricePerDay'] ?? 0).toDouble(),
      availableSeats: data['availableSeats'] ?? 0,
      amenities: List<String>.from(data['amenities'] ?? []),
    );
  }

  // ------------------------------------------------------------
  // CHECK IF SEAT IS ALREADY BOOKED
  // ------------------------------------------------------------

  Future<bool> isSeatBooked({
    required String spaceId,
    required int seatNumber,
    required DateTime date,
    required String time,
  }) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('spaceId', isEqualTo: spaceId)
        .where('seatNumber', isEqualTo: seatNumber)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final bookingDate = data['date'];

      final bookingTime = data['time'];

      if (bookingDate is! Timestamp) {
        continue;
      }

      if (bookingTime is! String) {
        continue;
      }

      final savedDate = bookingDate.toDate();

      // Compare date only.
      final sameDate =
          savedDate.year == date.year &&
          savedDate.month == date.month &&
          savedDate.day == date.day;

      // Compare selected time.
      final sameTime = bookingTime == time;

      if (sameDate && sameTime) {
        return true;
      }
    }

    return false;
  }

  // ------------------------------------------------------------
  // CREATE BOOKING
  // ------------------------------------------------------------

  Future<String> createBooking({
    required String spaceId,
    required String userId,
    required int seatNumber,
    required DateTime date,
    required String time,
    required double basePrice,
    required double convenienceFee,
    required double tax,
    required double totalPrice,
  }) async {
    // Check whether this seat is already booked.
    final alreadyBooked = await isSeatBooked(
      spaceId: spaceId,
      seatNumber: seatNumber,
      date: date,
      time: time,
    );

    // Prevent duplicate booking.
    if (alreadyBooked) {
      throw Exception(
        'This seat is already booked for the selected date and time.',
      );
    }

    // Create booking.
    final bookingRef = await _firestore.collection('bookings').add({
      'userId': userId,
      'spaceId': spaceId,
      'seatNumber': seatNumber,
      'date': Timestamp.fromDate(date),
      'time': time,
      'basePrice': basePrice,
      'convenienceFee': convenienceFee,
      'tax': tax,
      'totalPrice': totalPrice,

      // Payment hasn't happened yet.
      'bookingStatus': 'Pending',
      'paymentStatus': 'Pending',

      'createdAt': FieldValue.serverTimestamp(),
    });

    // Return Firebase-generated booking ID.
    return bookingRef.id;
  }

  // ------------------------------------------------------------
  // MARK BOOKING AS PAID
  // ------------------------------------------------------------

  Future<void> markBookingAsPaid(String bookingId) async {
    // Get the booking details
    final bookingDoc = await _firestore
        .collection('bookings')
        .doc(bookingId)
        .get();

    if (!bookingDoc.exists) {
      throw Exception('Booking not found.');
    }

    final bookingData = bookingDoc.data();

    if (bookingData == null) {
      throw Exception('Booking data not found.');
    }

    final spaceId = bookingData['spaceId'] as String;

    final seatNumber = bookingData['seatNumber'] as int;

    // References
    final bookingRef = _firestore.collection('bookings').doc(bookingId);

    final seatRef = _firestore
        .collection('spaces')
        .doc(spaceId)
        .collection('seats')
        .doc('S$seatNumber');

    // Update booking + seat together
    final batch = _firestore.batch();

    batch.update(bookingRef, {
      'paymentStatus': 'Paid',
      'bookingStatus': 'Confirmed',
      'paidAt': FieldValue.serverTimestamp(),
    });

    batch.update(seatRef, {'isOccupied': true});

    await batch.commit();
  }
}
