import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'models/space.dart';
import 'models/seat.dart';
import 'models/booking.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const CoWorkSpaceApp());
}

List<Space> filterSpacesByAmenity(List<Space> spaces, String amenity) {
  return spaces.where((space) {
    return space.amenities.contains(amenity);
  }).toList();
}

class CoWorkSpaceApp extends StatelessWidget {
  const CoWorkSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CoWorkSpace',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF8FAFA),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const MainNavigation();
        }

        return const LoginScreen();
      },
    );
  }
}

// ------------------------------------------------------------
// MAIN NAVIGATION
// ------------------------------------------------------------

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    DashboardScreen(),
    ExploreScreen(),
    BookingsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// DASHBOARD
// ------------------------------------------------------------

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox();
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CoWorkSpace',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // REAL USER NAME FROM FIRESTORE
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                String name = 'User';

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data =
                      snapshot.data!.data() as Map<String, dynamic>;

                  name = data['name'] ?? 'User';
                }

                return Text(
                  'Good morning, $name 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),

            const SizedBox(height: 4),

            Text(
              'Find your perfect workspace',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 20),

            // SEARCH
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExploreScreen(),
                  ),
                );
              },
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search coworking spaces',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Popular Amenities',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              children: [
                _amenityChip('Wi-Fi', Icons.wifi),
                _amenityChip(
                  'Meeting Rooms',
                  Icons.meeting_room,
                ),
                _amenityChip(
                  '24x7',
                  Icons.access_time,
                ),
                _amenityChip(
                  'Café',
                  Icons.coffee,
                ),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              'Popular Spaces',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('spaces')
                  .limit(3)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Text(
                    'No spaces available',
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>;

                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.business),
                        ),
                        title: Text(
                          data['name'] ?? 'Workspace',
                        ),
                        subtitle: Text(
                          data['location'] ?? '',
                        ),
                        trailing: Text(
                          '₹${data['pricePerDay']}/day',
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _amenityChip(String title, IconData icon) {
  return Chip(
    avatar: Icon(
      icon,
      size: 18,
    ),
    label: Text(title),
  );
}

// ------------------------------------------------------------
// EXPLORE
// ------------------------------------------------------------

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Space> spaces = [];
  bool isLoading = true;

  String searchQuery = '';

  List<String> activeFilters = [];

  @override
  void initState() {
    super.initState();
    loadSpaces();
  }

  Future<void> loadSpaces() async {
    try {
      final data = await _firestoreService.getSpaces();

      if (!mounted) return;

      setState(() {
        spaces = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      debugPrint('Error loading spaces: $e');
    }
  }

  List<Space> get filteredSpaces {
    List<Space> result = spaces;

    // Search filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();

      result = result.where((space) {
        return space.name.toLowerCase().contains(query) ||
            space.location.toLowerCase().contains(query) ||
            space.amenities.any(
              (amenity) => amenity.toLowerCase().contains(query),
            );
      }).toList();
    }

    // Amenity filters
    if (activeFilters.isNotEmpty) {
      result = result.where((space) {
        return activeFilters.every(
          (filter) => space.amenities.contains(filter),
        );
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore Spaces')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Explore Spaces',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Find a workspace that fits you',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search spaces...',
                      prefixIcon: const Icon(Icons.search),

                      suffixIcon: IconButton(
                        icon: const Icon(Icons.tune),
                        onPressed: () async {
                          final selectedFilters =
                              await Navigator.push<List<String>>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FilterScreen(),
                                ),
                              );

                          if (selectedFilters == null) return;

                          setState(() {
                            activeFilters = selectedFilters;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Wi-Fi'),
                        onSelected: (_) {
                          setState(() {
                            searchQuery = 'Wi-Fi';
                          });
                        },
                      ),

                      FilterChip(
                        label: const Text('Meeting Room'),
                        onSelected: (_) {
                          setState(() {
                            searchQuery = 'Meeting Rooms';
                          });
                        },
                      ),

                      FilterChip(
                        label: const Text('Parking'),
                        onSelected: (_) {
                          setState(() {
                            searchQuery = 'Parking';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredSpaces.isEmpty
                  ? const Center(
                      child: Text(
                        'No coworking spaces found.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredSpaces.length,
                      itemBuilder: (context, index) {
                        final space = filteredSpaces[index];

                        return _spaceCard(context, space);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _spaceCard(BuildContext context, Space space) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),

      child: Padding(
        padding: const EdgeInsets.all(15),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              width: double.infinity,

              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
              ),

              child: const Icon(
                Icons.business_center,
                size: 45,
                color: Colors.teal,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              space.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            Text(space.location),

            const SizedBox(height: 6),

            Row(
              children: [
                Text('⭐ ${space.rating}'),

                const Spacer(),

                Text(
                  '₹${space.pricePerDay.toStringAsFixed(0)}/day',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              '${space.availableSeats} seats available',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 6,

              children: space.amenities.take(3).map((amenity) {
                return Chip(
                  label: Text(amenity),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SpaceDetailsScreen(
                        spaceId: space.id,
                        name: space.name,
                        location: space.location,
                        rating: space.rating.toString(),
                        price: '₹${space.pricePerDay.toStringAsFixed(0)}/day',
                      ),
                    ),
                  );
                },

                child: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// FILTER
// ------------------------------------------------------------

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  bool wifi = false;
  bool meetingRoom = false;
  bool parking = false;
  bool cafe = false;
  bool ac = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Filter Amenities')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Amenities',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          CheckboxListTile(
            title: const Text('Wi-Fi'),
            value: wifi,
            onChanged: (value) {
              setState(() {
                wifi = value ?? false;
              });
            },
          ),

          CheckboxListTile(
            title: const Text('Meeting Rooms'),
            value: meetingRoom,
            onChanged: (value) {
              setState(() {
                meetingRoom = value ?? false;
              });
            },
          ),

          CheckboxListTile(
            title: const Text('Parking'),
            value: parking,
            onChanged: (value) {
              setState(() {
                parking = value ?? false;
              });
            },
          ),

          CheckboxListTile(
            title: const Text('Café'),
            value: cafe,
            onChanged: (value) {
              setState(() {
                cafe = value ?? false;
              });
            },
          ),

          CheckboxListTile(
            title: const Text('AC'),
            value: ac,
            onChanged: (value) {
              setState(() {
                ac = value ?? false;
              });
            },
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final selectedFilters = <String>[];

                if (wifi) selectedFilters.add('Wi-Fi');
                if (meetingRoom) selectedFilters.add('Meeting Rooms');
                if (parking) selectedFilters.add('Parking');
                if (cafe) selectedFilters.add('Café');
                if (ac) selectedFilters.add('AC');

                Navigator.pop(context, selectedFilters);
              },
              child: const Text('Apply Filters'),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context, <String>[]);
              },
              child: const Text('Clear Filters'),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// SPACE DETAILS
// ------------------------------------------------------------

class SpaceDetailsScreen extends StatelessWidget {
  final String name;
  final String location;
  final String rating;
  final String price;
  final String spaceId;

  const SpaceDetailsScreen({
    super.key,
    required this.spaceId,
    required this.name,
    required this.location,
    required this.rating,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Space Details')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------
            // SPACE IMAGE / PLACEHOLDER
            // ------------------------------------------------
            Container(
              height: 200,
              width: double.infinity,

              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(18),
              ),

              child: const Icon(Icons.business, size: 70, color: Colors.teal),
            ),

            const SizedBox(height: 20),

            // ------------------------------------------------
            // SPACE NAME
            // ------------------------------------------------
            Text(
              name,

              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // ------------------------------------------------
            // LOCATION + RATING
            // ------------------------------------------------
            Text(
              '$location • ⭐ $rating',

              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),

            const SizedBox(height: 16),

            // ------------------------------------------------
            // PRICE
            // ------------------------------------------------
            Text(
              price,

              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),

            const SizedBox(height: 24),

            // ------------------------------------------------
            // AMENITIES
            // ------------------------------------------------
            const Text(
              'Amenities',

              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            const Wrap(
              spacing: 8,
              runSpacing: 8,

              children: [
                Chip(avatar: Icon(Icons.wifi), label: Text('Wi-Fi')),

                Chip(
                  avatar: Icon(Icons.meeting_room),
                  label: Text('Meeting Rooms'),
                ),

                Chip(avatar: Icon(Icons.ac_unit), label: Text('AC')),

                Chip(avatar: Icon(Icons.local_cafe), label: Text('Café')),

                Chip(avatar: Icon(Icons.local_parking), label: Text('Parking')),
              ],
            ),

            const SizedBox(height: 28),

            // ------------------------------------------------
            // ABOUT
            // ------------------------------------------------
            const Text(
              'About this space',

              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'A comfortable and modern coworking space with '
              'high-speed internet, meeting rooms and flexible seating.',
            ),

            const SizedBox(height: 30),

            // ------------------------------------------------
            // SELECT SEAT BUTTON
            // ------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 52,

              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (_) => SeatSelectionScreen(
                        // IMPORTANT:
                        // Pass the actual Firestore space ID.
                        spaceId: spaceId,
                      ),
                    ),
                  );
                },

                child: const Text('Select Seat'),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// SEAT SELECTION - BASIC FOR NOW
// ------------------------------------------------------------

class SeatSelectionScreen extends StatefulWidget {
  final String spaceId;

  const SeatSelectionScreen({super.key, required this.spaceId});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Seat> seats = [];
  bool isLoading = true;

  int? selectedSeat;

  @override
  void initState() {
    super.initState();
    loadSeats();
  }

  Future<void> loadSeats() async {
    try {
      final data = await _firestoreService.getSeats(widget.spaceId);

      if (!mounted) return;

      setState(() {
        seats = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      debugPrint('Error loading seats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Seat')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Your Seat',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text('Select an available seat'),

            const SizedBox(height: 30),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : seats.isEmpty
                  ? const Center(child: Text('No seats available.'))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: seats.length,
                      itemBuilder: (context, index) {
                        final seat = seats[index];

                        final seatNumber = seat.number;
                        final occupied = seat.isOccupied;
                        final selected = selectedSeat == seatNumber;

                        return GestureDetector(
                          onTap: occupied
                              ? null
                              : () {
                                  setState(() {
                                    selectedSeat = seatNumber;
                                  });
                                },
                          child: Container(
                            decoration: BoxDecoration(
                              color: occupied
                                  ? Colors.grey.shade300
                                  : selected
                                  ? Colors.teal
                                  : Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'S$seatNumber',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: occupied || selected
                                      ? Colors.white
                                      : Colors.teal.shade800,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Available'),

                const SizedBox(width: 20),

                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Occupied'),
              ],
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: selectedSeat == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingSummaryScreen(
                              spaceId: widget.spaceId,
                              seatNumber: selectedSeat!,
                            ),
                          ),
                        );
                      },
                child: const Text('Continue to Summary'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// BOOKING SUMMARY
// ------------------------------------------------------------

class BookingSummaryScreen extends StatefulWidget {
  final String spaceId;
  final int seatNumber;

  const BookingSummaryScreen({
    super.key,
    required this.spaceId,
    required this.seatNumber,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Space? space;
  bool isLoading = true;
  bool isCreatingBooking = false;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  final double convenienceFee = 20.0;

  @override
  void initState() {
    super.initState();
    loadSpace();
  }

  // ------------------------------------------------------------
  // LOAD SPACE FROM FIRESTORE
  // ------------------------------------------------------------

  Future<void> loadSpace() async {
    try {
      final data =
          await _firestoreService.getSpaceById(widget.spaceId);

      if (!mounted) return;

      setState(() {
        space = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      debugPrint('Error loading space: $e');
    }
  }

  // ------------------------------------------------------------
  // SELECT BOOKING DATE
  // ------------------------------------------------------------

  Future<void> selectDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(
        const Duration(days: 90),
      ),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  // ------------------------------------------------------------
  // SELECT BOOKING TIME
  // ------------------------------------------------------------

  Future<void> selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(
        hour: 10,
        minute: 0,
      ),
    );

    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  // ------------------------------------------------------------
  // FORMAT DATE
  // ------------------------------------------------------------

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // ------------------------------------------------------------
  // FORMAT TIME
  // ------------------------------------------------------------

  String formatTime(TimeOfDay time) {
    return time.format(context);
  }

  // ------------------------------------------------------------
  // CREATE BOOKING IN FIRESTORE
  // ------------------------------------------------------------

  Future<void> createBookingAndContinue(
  double total,
    ) async {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return;
      }

      if (selectedDate == null ||
          selectedTime == null ||
          space == null) {
        return;
      }

    setState(() {
      isCreatingBooking = true;
    });

    try {
      final basePrice = space!.pricePerDay;

      final tax =
          (basePrice + convenienceFee) * 0.18;

      final time = selectedTime!.format(context);

      // Save booking to Firestore
      final bookingId =
          await _firestoreService.createBooking(
        userId: user.uid,
        spaceId: widget.spaceId,
        seatNumber: widget.seatNumber,
        date: selectedDate!,
        time: time,
        basePrice: basePrice,
        convenienceFee: convenienceFee,
        tax: tax,
        totalPrice: total,
      );

      if (!mounted) return;

      // Move to payment screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
          total: total,
          bookingId: bookingId,
        ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create booking: $e',
          ),
        ),
      );

      debugPrint(
        'Error creating booking: $e',
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isCreatingBooking = false;
      });
    }
  }

  // ------------------------------------------------------------
  // BUILD UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {


    // Loading
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Space not found
    if (space == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Workspace not found.',
          ),
        ),
      );
    }

    // Dynamic pricing
    final basePrice = space!.pricePerDay;

    final gst =
        (basePrice + convenienceFee) * 0.18;

    final total =
        basePrice + convenienceFee + gst;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Booking Summary',
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ------------------------------------------------
            // SPACE NAME
            // ------------------------------------------------

            Text(
              space!.name,

              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            // ------------------------------------------------
            // LOCATION
            // ------------------------------------------------

            Text(
              space!.location,

              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 25),

            // ------------------------------------------------
            // BOOKING DATE
            // ------------------------------------------------

            const Text(
              'Booking Date',

              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: isCreatingBooking
                    ? null
                    : selectDate,

                icon: const Icon(
                  Icons.calendar_today,
                ),

                label: Text(
                  selectedDate == null
                      ? 'Select Date'
                      : formatDate(
                          selectedDate!,
                        ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ------------------------------------------------
            // BOOKING TIME
            // ------------------------------------------------

            const Text(
              'Booking Time',

              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: isCreatingBooking
                    ? null
                    : selectTime,

                icon: const Icon(
                  Icons.access_time,
                ),

                label: Text(
                  selectedTime == null
                      ? 'Select Time'
                      : formatTime(
                          selectedTime!,
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ------------------------------------------------
            // SELECTED SEAT
            // ------------------------------------------------

            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(15),

              decoration: BoxDecoration(
                color: Colors.teal.shade50,

                borderRadius:
                    BorderRadius.circular(12),
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.event_seat,
                    color: Colors.teal,
                  ),

                  const SizedBox(width: 10),

                  Text(
                    'Selected Seat: S${widget.seatNumber}',

                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ------------------------------------------------
            // PRICE BREAKDOWN
            // ------------------------------------------------

            const Divider(),

            _priceRow(
              'Workspace',
              basePrice,
            ),

            _priceRow(
              'Convenience Fee',
              convenienceFee,
            ),

            _priceRow(
              'GST (18%)',
              gst,
            ),

            const Divider(),

            _priceRow(
              'Total',
              total,
              bold: true,
            ),

            const SizedBox(height: 20),

            // ------------------------------------------------
            // CONTINUE TO PAYMENT
            // ------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 52,

              child: FilledButton(
                onPressed:
                    selectedDate == null ||
                            selectedTime == null ||
                            isCreatingBooking
                        ? null
                        : () {
                            createBookingAndContinue(
                              total,
                            );
                          },

                child: isCreatingBooking
                    ? const SizedBox(
                        width: 22,
                        height: 22,

                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Continue to Payment • ₹${total.toStringAsFixed(0)}',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PRICE ROW
  // ------------------------------------------------------------

  Widget _priceRow(
    String title,
    double amount, {
    bool bold = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 6,
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

        children: [
          Text(
            title,

            style: TextStyle(
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),

          Text(
            '₹${amount.toStringAsFixed(2)}',

            style: TextStyle(
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// PAYMENT
// ------------------------------------------------------------

class PaymentScreen extends StatefulWidget {
  final double total;
  final String bookingId;

  const PaymentScreen({
    super.key,
    required this.total,
    required this.bookingId,
  });

  @override
  State<PaymentScreen> createState() =>
      _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentMethod = 'UPI';
  bool isProcessing = false;

  Future<void> completePayment(
    BuildContext context,
  ) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final firestoreService = FirestoreService();

      // Simulate payment processing
      await Future.delayed(
        const Duration(seconds: 2),
      );

      // Update booking in Firebase
      await firestoreService.markBookingAsPaid(
        widget.bookingId,
      );

      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmationScreen(
  bookingId: widget.bookingId,
),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment failed: $e',
          ),
        ),
      );
    }
  }

  Widget paymentMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected =
        selectedPaymentMethod == title;

    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: isSelected
            ? const Icon(
                Icons.check_circle,
                color: Colors.green,
              )
            : const Icon(
                Icons.radio_button_unchecked,
              ),
        onTap: isProcessing
            ? null
            : () {
                setState(() {
                  selectedPaymentMethod = title;
                });
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'Complete Payment',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Choose a payment method',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 24),

            paymentMethodCard(
              title: 'UPI',
              subtitle: 'Pay using UPI',
              icon: Icons.account_balance_wallet,
            ),

            paymentMethodCard(
              title: 'Credit / Debit Card',
              subtitle: 'Pay using your card',
              icon: Icons.credit_card,
            ),

            paymentMethodCard(
              title: 'Net Banking',
              subtitle: 'Pay using your bank account',
              icon: Icons.account_balance,
            ),

            const Spacer(),

            Text(
              'Payment Method: $selectedPaymentMethod',
              style: const TextStyle(
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Total: ₹${widget.total.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 52,

              child: FilledButton(
                onPressed: isProcessing
                    ? null
                    : () {
                        completePayment(context);
                      },

                child: isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Pay ₹${widget.total.toStringAsFixed(0)}',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ------------------------------------------------------------
// BOOKINGS
// ------------------------------------------------------------

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  String formatBookingDate(Timestamp timestamp) {
    final date = timestamp.toDate();

    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return const Center(
      child: Text('Please log in'),
    );
  }
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'My Bookings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('userId', isEqualTo: user!.uid)
                .orderBy(
                  'createdAt',
                  descending: true,
                )
                .snapshots(),

            builder: (context, snapshot) {
              // ------------------------------------------------
              // LOADING
              // ------------------------------------------------

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // ------------------------------------------------
              // ERROR
              // ------------------------------------------------

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Error loading bookings:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              // ------------------------------------------------
              // NO BOOKINGS
              // ------------------------------------------------

              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 60,
                          color: Colors.grey,
                        ),

                        SizedBox(height: 12),

                        Text(
                          'No bookings yet.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 5),

                        Text(
                          'Your confirmed bookings will appear here.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final bookings =
                  snapshot.data!.docs;

              // ------------------------------------------------
              // BOOKINGS LIST
              // ------------------------------------------------

              return Column(
                children: bookings.map((doc) {
                  final data =
                      doc.data()
                          as Map<String, dynamic>;

                  final spaceId =
                      data['spaceId'] ?? '';

                  final seatNumber =
                      data['seatNumber'] ?? 0;

                  final time =
                      data['time'] ?? '';

                  final totalPrice =
                      (data['totalPrice'] ?? 0)
                          .toDouble();

                  final bookingStatus =
                      data['bookingStatus'] ??
                          'Pending';

                  final paymentStatus =
                      data['paymentStatus'] ??
                          'Pending';

                  final date =
                      data['date'];

                  String formattedDate =
                      'Date unavailable';

                  if (date is Timestamp) {
                    formattedDate =
                        formatBookingDate(date);
                  }

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('spaces')
                        .doc(spaceId)
                        .get(),

                    builder:
                        (context, spaceSnapshot) {
                      String spaceName =
                          'Coworking Space';

                      String location = '';

                      if (spaceSnapshot.hasData &&
                          spaceSnapshot
                              .data!
                              .exists) {
                        final spaceData =
                            spaceSnapshot.data!
                                    .data()
                                as Map<String,
                                    dynamic>;

                        spaceName =
                            spaceData['name'] ??
                                'Coworking Space';

                        location =
                            spaceData['location'] ??
                                '';
                      }

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 16,
                        ),

                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            16,
                          ),

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              // --------------------------------
                              // SPACE
                              // --------------------------------

                              Row(
                                children: [
                                  const CircleAvatar(
                                    child: Icon(
                                      Icons.business,
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 12,
                                  ),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          spaceName,

                                          style:
                                              const TextStyle(
                                            fontSize:
                                                17,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),

                                        if (location
                                            .isNotEmpty)
                                          Text(
                                            location,

                                            style:
                                                TextStyle(
                                              color: Colors
                                                  .grey
                                                  .shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  Chip(
                                    label: Text(
                                      bookingStatus,
                                    ),

                                    backgroundColor:
                                        bookingStatus ==
                                                'Confirmed'
                                            ? Colors
                                                .greenAccent
                                            : Colors
                                                .orangeAccent,
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 16,
                              ),

                              // --------------------------------
                              // DATE
                              // --------------------------------

                              Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .calendar_today,
                                    size: 18,
                                  ),

                                  const SizedBox(
                                    width: 8,
                                  ),

                                  Text(
                                    formattedDate,
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              // --------------------------------
                              // TIME
                              // --------------------------------

                              Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .access_time,
                                    size: 18,
                                  ),

                                  const SizedBox(
                                    width: 8,
                                  ),

                                  Text(
                                    time,
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              // --------------------------------
                              // SEAT
                              // --------------------------------

                              Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .event_seat,
                                    size: 18,
                                  ),

                                  const SizedBox(
                                    width: 8,
                                  ),

                                  Text(
                                    'Seat S$seatNumber',
                                  ),
                                ],
                              ),

                              const Divider(
                                height: 24,
                              ),

                              // --------------------------------
                              // PRICE + PAYMENT
                              // --------------------------------

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,

                                children: [
                                  Text(
                                    'Total',

                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),

                                  Text(
                                    '₹${totalPrice.toStringAsFixed(2)}',

                                    style:
                                        const TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              Text(
                                'Payment: $paymentStatus',

                                style: TextStyle(
                                  color:
                                      paymentStatus ==
                                              'Paid'
                                          ? Colors
                                              .green
                                          : Colors
                                              .orange,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// PROFILE
// ------------------------------------------------------------

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox();
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 30),

          const CircleAvatar(
            radius: 45,
            child: Icon(
              Icons.person,
              size: 45,
            ),
          ),

          const SizedBox(height: 12),

          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              String name = 'User';
              String email = user.email ?? '';

              if (snapshot.hasData &&
                  snapshot.data!.exists) {
                final data =
                    snapshot.data!.data()
                        as Map<String, dynamic>;

                name = data['name'] ?? 'User';
                email = data['email'] ?? email;
              }

              return Column(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(email),
                ],
              );
            },
          ),

          const SizedBox(height: 30),

          const ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Account'),
            trailing: Icon(Icons.chevron_right),
          ),

          const ListTile(
            leading: Icon(Icons.payment),
            title: Text('Payment Methods'),
            trailing: Icon(Icons.chevron_right),
          ),

          const ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
            trailing: Icon(Icons.chevron_right),
          ),

          const SizedBox(height: 20),

          // LOGOUT
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () async {
              final shouldLogout =
                  await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Logout'),
                    content: const Text(
                      'Are you sure you want to logout?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );

              if (shouldLogout == true) {
                await logout(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

class ConfirmationScreen extends StatelessWidget {
  final String bookingId;

  const ConfirmationScreen({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .snapshots(),

        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Booking not found
          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Booking details not found.',
              ),
            );
          }

          final booking =
              snapshot.data!.data()
                  as Map<String, dynamic>;

          final spaceId =
              booking['spaceId'] ?? '';

          final seatNumber =
              booking['seatNumber'] ?? 0;

          final dateValue = booking['date'];
          final timeValue = booking['time'];

          String formattedDate = '';

          if (dateValue is Timestamp) {
            final date = dateValue.toDate();

            formattedDate =
                '${date.day.toString().padLeft(2, '0')}/'
                '${date.month.toString().padLeft(2, '0')}/'
                '${date.year}';
          } else {
            formattedDate = dateValue?.toString() ?? '';
          }

          String formattedTime = '';

          if (timeValue is Timestamp) {
            final time = timeValue.toDate();

            final hour = time.hour > 12
                ? time.hour - 12
                : time.hour == 0
                    ? 12
                    : time.hour;

            final minute =
                time.minute.toString().padLeft(2, '0');

            final period = time.hour >= 12 ? 'PM' : 'AM';

            formattedTime =
                '$hour:$minute $period';
          } else {
            formattedTime = timeValue?.toString() ?? '';
          }

          final totalPrice =
              booking['totalPrice'] ?? 0;

          final paymentStatus =
              booking['paymentStatus'] ?? 'Pending';

          final bookingStatus =
              booking['status'] ?? 'Pending';

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('spaces')
                .doc(spaceId)
                .get(),

            builder: (context, spaceSnapshot) {
              if (spaceSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              String spaceName = 'Coworking Space';

              if (spaceSnapshot.hasData &&
                  spaceSnapshot.data!.exists) {
                final spaceData =
                    spaceSnapshot.data!.data()
                        as Map<String, dynamic>;

                spaceName =
                    spaceData['name'] ?? spaceName;
              }

              return Padding(
                padding: const EdgeInsets.all(24),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.center,

                  children: [
                    const SizedBox(height: 20),

                    const Icon(
                      Icons.check_circle,
                      size: 90,
                      color: Colors.green,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Booking Confirmed!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Your booking has been successfully confirmed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 30),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),

                        child: Column(
                          children: [
                            _detailRow(
                              'Workspace',
                              spaceName,
                            ),

                            const Divider(),

                            _detailRow(
                              'Seat',
                              'Seat $seatNumber',
                            ),

                            const Divider(),

                            _detailRow(
                              'Date',
                              formattedDate,
                            ),

                            _detailRow(
                              'Time',
                              formattedTime,
                            ),

                            const Divider(),

                            _detailRow(
                              'Total Paid',
                              '₹${totalPrice.toString()}',
                            ),

                            const Divider(),

                            _detailRow(
                              'Payment',
                              paymentStatus,
                            ),

                            const Divider(),

                            _detailRow(
                              'Booking',
                              bookingStatus,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.popUntil(
                            context,
                            (route) => route.isFirst,
                          );
                        },
                        child: const Text(
                          'Back to Home',
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}