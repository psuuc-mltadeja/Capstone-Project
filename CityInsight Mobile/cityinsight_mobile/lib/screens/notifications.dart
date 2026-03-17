import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String? currentUsername;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    fetchCurrentUserDetails();
  }

  // Fetch the current user's username and ID from Firestore
  Future<void> fetchCurrentUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          currentUsername = "${data?['firstname']} ${data?['lastname']}";
          currentUserId = user.uid;
        });
      } else {
        print("No user document found for UID: ${user.uid}");
      }
    } else {
      print("No user is signed in.");
    }
  }

  // Stream for reports visible to the current user
  Stream<QuerySnapshot> fetchVisibleReports() {
    return FirebaseFirestore.instance.collection('reports').snapshots();
  }

  // Stream for SOS requests visible to the current user
  Stream<QuerySnapshot> fetchVisibleSosRequests() {
    return FirebaseFirestore.instance.collection('sosreqs').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
      ),
      body: currentUsername == null || currentUserId == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Incident Reports Section
                  const Text(
                    "Incident Reports",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4A4A), // Soft dark gray
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: fetchVisibleReports(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return const Center(
                              child: Text("Error fetching data."));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                              child: Text("No incident reports found."));
                        }

                        final reports = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: reports.length,
                          itemBuilder: (context, index) {
                            var report =
                                reports[index].data() as Map<String, dynamic>;
                            bool isCurrentUserReport =
                                report['username'] == currentUsername;

                            if (isCurrentUserReport &&
                                report['status'] == 'responded') {
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      15), // Slight rounding for modern look
                                ),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 12),
                                color: const Color(
                                    0xFFF4F6F9), // Light gray background
                                child: ListTile(
                                  leading: const Icon(Icons.report_problem,
                                      color: Colors.blue),
                                  title: const Text(
                                    "Your incident report has been responded to!",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue),
                                  ),
                                  subtitle: const Text(
                                    "Click for more details.",
                                    style: TextStyle(color: Colors.blueGrey),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ReportDetailsScreen(
                                          reportId: reports[index].id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }

                            if (!isCurrentUserReport &&
                                report['status'] == 'approved') {
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      15), // Slight rounding for modern look
                                ),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 12),
                                color: const Color(
                                    0xFFF4F6F9), // Light gray background
                                child: ListTile(
                                  leading: const Icon(
                                      Icons.notifications_active,
                                      color: Colors.blue),
                                  title: const Text(
                                    "A new incident has been reported!",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue),
                                  ),
                                  subtitle: const Text(
                                    "Click for more details.",
                                    style: TextStyle(color: Colors.blueGrey),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ReportDetailsScreen(
                                          reportId: reports[index].id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }

                            return const SizedBox
                                .shrink(); // No display for others
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(),

                  // SOS Requests Section
                  const Text(
                    "SOS Reports",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4A4A), // Soft dark gray
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: fetchVisibleSosRequests(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return const Center(
                              child: Text("Error fetching SOS requests."));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                              child: Text("No SOS requests found."));
                        }

                        final sosRequests = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: sosRequests.length,
                          itemBuilder: (context, index) {
                            var sosRequest = sosRequests[index].data()
                                as Map<String, dynamic>;
                            bool isCurrentUserRequest =
                                sosRequest['userId'] == currentUserId;

                            if (!isCurrentUserRequest) {
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      15), // Slight rounding for modern look
                                ),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 12),
                                color: const Color(
                                    0xFFFEE2E2), // Light red background
                                child: ListTile(
                                  leading: const Icon(Icons.warning,
                                      color: Colors.red),
                                  title: const Text(
                                    "Someone needs help!",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red),
                                  ),
                                  subtitle: const Text(
                                    "Click for more details.",
                                    style: TextStyle(color: Colors.blueGrey),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SosRequestDetailsScreen(
                                          requestId: sosRequests[index].id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }

                            return const SizedBox
                                .shrink(); // No display for own requests
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class ReportDetailsScreen extends StatelessWidget {
  final String reportId;

  const ReportDetailsScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: const Text(
          "Report Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('reports')
            .doc(reportId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(child: Text("Error fetching report details."));
          }

          final report = snapshot.data!.data() as Map<String, dynamic>;

          // Fetch image URL from Firestore
          String imageUrl = report['imageUrl'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['title'] ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Display the image from Firebase Storage
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 50,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 50,
                    ),
                  ),

                const SizedBox(height: 16),

                // Description Section
                const Text(
                  "Description:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report['body'] ?? 'No Description',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 16),

                // Date Section
                const Text(
                  "Reported On:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report['date'] != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                              report['date'].seconds * 1000)
                          .toString()
                      : 'No Date',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 16),

                // Conditionally display the Status Section
                if (report['status'] != "approved") ...[
                  const Text(
                    "Status:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report['status'] ?? 'No Status Available',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class SosRequestDetailsScreen extends StatelessWidget {
  final String requestId;

  const SosRequestDetailsScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "SOS Request Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('sosreqs')
            .doc(requestId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(child: Text("Error fetching request details."));
          }

          final sosRequest = snapshot.data!.data() as Map<String, dynamic>;

          // Extract details
          String timestamp = sosRequest['timestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                      sosRequest['timestamp'].seconds * 1000)
                  .toString()
              : 'No Timestamp';
          String latitude = sosRequest['latitude']?.toString() ?? 'Unknown';
          String longitude = sosRequest['longitude']?.toString() ?? 'Unknown';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  "SOS Request Details",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Details Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow("Timestamp", timestamp),
                        const Divider(),
                        _buildDetailRow("Latitude", latitude),
                        const Divider(),
                        _buildDetailRow("Longitude", longitude),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Button to view location
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (latitude != 'Unknown' && longitude != 'Unknown') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MapScreen(
                              latitude: double.parse(latitude),
                              longitude: double.parse(longitude),
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Invalid location coordinates."),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.map),
                    label: const Text("View on Map"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper widget to build a row for each detail
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

// Helper widget to build a row for each detail
Widget _buildDetailRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.black54,
        ),
      ),
    ],
  );
}

class MapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const MapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  LatLng? _userLocation;
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Fetch the current location of the user
  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
    });

    // Add polyline to destination
    _addPolyline(LatLng(widget.latitude, widget.longitude));
  }

  // Request location permissions
  Future<bool> _handleLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required to show the route.'),
          ),
        );
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission is permanently denied.'),
        ),
      );
      return false;
    }
    return true;
  }

  // Decode ORS polyline
  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      polyline.add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }
    return polyline;
  }

  // Fetch polyline data from ORS API
  Future<List<LatLng>> _getRoutePolyline(
      LatLng origin, LatLng destination) async {
    final apiKey =
        '5b3ce3597851110001cf6248f5681182c98e46e09350c1b3e224d59a'; // Replace with your ORS API key
    final url =
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${origin.longitude},${origin.latitude}&end=${destination.longitude},${destination.latitude}';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> coordinates =
          data['features'][0]['geometry']['coordinates'];

      return coordinates.map((coord) {
        return LatLng(coord[1],
            coord[0]); // Convert [longitude, latitude] to [latitude, longitude]
      }).toList();
    } else {
      throw Exception('Failed to fetch route data: ${response.body}');
    }
  }

  // Calculate distance between two points
  double calculateDistance(LatLng origin, LatLng destination) {
    return Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );
  }

  // Add polyline to the map
  Future<void> _addPolyline(LatLng destination) async {
    if (_userLocation != null) {
      try {
        double distance = calculateDistance(_userLocation!, destination);

        // Skip polyline generation if the distance is too large (e.g., >100km)
        if (distance > 100000.0) {
          print(
              'Destination too far: $distance meters. Skipping polyline generation.');
          return;
        }

        final points = await _getRoutePolyline(_userLocation!, destination);
        if (points.isNotEmpty) {
          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: points,
                color: Colors.blue,
                width: 5,
              ),
            );
          });
        }
      } catch (e) {
        print('Error fetching route: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: const Text(
          "SOS Report Location",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.latitude, widget.longitude),
                zoom: 15.0,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('sos_location'),
                  position: LatLng(widget.latitude, widget.longitude),
                  infoWindow: const InfoWindow(
                    title: "SOS Location",
                    snippet: "Reported Position",
                  ),
                ),
                Marker(
                  markerId: const MarkerId('current_location'),
                  position: _userLocation!,
                  infoWindow: const InfoWindow(
                    title: "Your Location",
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen),
                ),
              },
              polylines: _polylines,
            ),
    );
  }
}
