import 'dart:convert';
import 'package:cityinsight_mobile/screens/details-screen.dart';
import 'package:cityinsight_mobile/screens/notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as map_tool;

class HomeScreen extends StatefulWidget {
  final String userId;
  final String currentMap;
  final Function(String) onMapChange;

  const HomeScreen(
      {super.key,
      required this.userId,
      required this.currentMap,
      required this.onMapChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool showIndicator = false;
  String? currentUsername;
  bool showNotificationBar = false;
  String notificationMessage = "";
  List<Map<String, dynamic>> userSosRequests = [];
  String? currentUserUid;
  DateTime? latestReportTimestamp;
  DateTime? latestSosTimestamp;

  static const initialPosition = LatLng(15.987770817221056, 120.57319298046644);
  late GoogleMapController mapController;
  final PanelController _panelController = PanelController();
  Set<Marker> _markers = {};
  String? _selectedCollection;
  BitmapDescriptor customIcon = BitmapDescriptor.defaultMarker;
  bool _isPolylineVisible = false;
  DateTime? latestTimestamp;

  Set<Polygon> polygons = {};
  Map<String, int> crimeCounts = {};
  bool isLoading = true;
  String? currentZone;
  bool hasShownModal = false;

  // * Lists to hold fetched data
  List<QueryDocumentSnapshot> _crimes = [];
  List<QueryDocumentSnapshot> _floods = [];
  List<QueryDocumentSnapshot> _evacs = [];
  List<QueryDocumentSnapshot> _hospitals = [];
  List<QueryDocumentSnapshot> _stations = [];

  // * polyline
  Set<Polyline> _polylines = {};
  LatLng? _userLocation;

  LatLng nearestHospital = LatLng(14.5995, 120.9842);
  LatLng nearestEvacCenter = LatLng(14.6095, 120.9742);

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    _selectedCollection = null;
    fetchMarkers();
    customMarker();
    fetchUserData();
    monitorNewReportsAndSosRequests();
    _fetchPolygonsWithCrimeData();
    _startTrackingUserLocation();
  }

  Future<void> _fetchPolygonsWithCrimeData() async {
    try {
      final barangaysSnapshot =
          await FirebaseFirestore.instance.collection('barangays').get();

      final crimesSnapshot =
          await FirebaseFirestore.instance.collection('crimes').get();

      // Count crimes per barangay
      for (var doc in crimesSnapshot.docs) {
        final brgy = doc['brgy'];
        if (brgy != null) {
          crimeCounts[brgy] = (crimeCounts[brgy] ?? 0) + 1;
        }
      }

      Set<Polygon> filteredPolygons = {};
      for (var doc in barangaysSnapshot.docs) {
        final brgyName = doc['name'];
        final crimeCount = crimeCounts[brgyName] ?? 0;

        if (crimeCount > 0) {
          List<LatLng> points = [];
          int index = 1;

          while (doc.data().containsKey('point$index')) {
            final geoPoint = doc['point$index'];
            if (geoPoint != null && geoPoint is GeoPoint) {
              points.add(LatLng(geoPoint.latitude, geoPoint.longitude));
            }
            index++;
          }

          if (points.isNotEmpty) {
            filteredPolygons.add(
              Polygon(
                polygonId: PolygonId(brgyName),
                points: points,
                fillColor: Colors.red.withOpacity(0.3),
                strokeColor: Colors.red,
                strokeWidth: 2,
              ),
            );
          }
        }
      }

      setState(() {
        polygons = filteredPolygons;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching polygons: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _startTrackingUserLocation() {
    Geolocator.getPositionStream().listen((Position position) {
      LatLng currentLocation = LatLng(position.latitude, position.longitude);
      _checkLocationInPolygon(currentLocation);
    });
  }

  void _checkLocationInPolygon(LatLng currentLocation) {
    for (var polygon in polygons) {
      List<map_tool.LatLng> polygonPoints = polygon.points
          .map((point) => map_tool.LatLng(point.latitude, point.longitude))
          .toList();

      if (map_tool.PolygonUtil.containsLocation(
          map_tool.LatLng(currentLocation.latitude, currentLocation.longitude),
          polygonPoints,
          false)) {
        if (currentZone != polygon.polygonId.value) {
          currentZone = polygon.polygonId.value;

          // Show modal for the new zone
          _showCrimeZoneModal(
            currentZone!,
            crimeCounts[currentZone!] ?? 0,
          );
        }
        return;
      }
    }
    currentZone = null;
  }

  void _showCrimeZoneModal(String zoneName, int crimeCount) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Crime Alert"),
          content: Text(
            "You have entered $zoneName, where $crimeCount crimes have been reported.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Fetch the current user's details
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();
          setState(() {
            currentUsername = "${data?['firstname']} ${data?['lastname']}";
          });
        } else {
          print("No user document found for UID: ${user.uid}");
        }

        // Fetch SOS requests NOT created by the current user
        final sosRequestsSnapshot = await FirebaseFirestore.instance
            .collection('sosreqs')
            .where('userId',
                isNotEqualTo: user.uid) // Exclude current user's reports
            .get();

        if (sosRequestsSnapshot.docs.isNotEmpty) {
          setState(() {
            userSosRequests = sosRequestsSnapshot.docs.map((doc) {
              return {
                'id': doc.id,
                ...doc.data(),
              };
            }).toList();
          });
        } else {
          print("No SOS requests from other users.");
        }
      } catch (error) {
        print("Error fetching user data or SOS requests: $error");
      }
    } else {
      print("No user is signed in.");
    }
  }

  void monitorNewReportsAndSosRequests() {
    _listenToReports();
    _listenToSosRequests();
  }

  void _listenToReports() {
    FirebaseFirestore.instance
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      print(
          "Incident Report Listener triggered with ${snapshot.docs.length} documents.");
      for (var doc in snapshot.docs) {
        _processIncidentReport(doc);
      }
    });
  }

  void _processIncidentReport(QueryDocumentSnapshot doc) {
    String reportUsername = doc['username'];
    Timestamp reportTimestamp = doc['timestamp'];
    String reportMessage = "";

    if (currentUsername == null) return;

    if (reportUsername == currentUsername && doc['status'] == 'responded') {
      reportMessage = "Your incident report has been responded to!";
    } else if (doc['status'] == 'approved') {
      reportMessage = "A new incident has been reported!";
    }

    if (reportMessage.isNotEmpty &&
        (latestReportTimestamp == null ||
            reportTimestamp.toDate().isAfter(latestReportTimestamp!))) {
      updateNotificationBar(reportMessage, reportTimestamp.toDate());
      latestReportTimestamp = reportTimestamp.toDate();
      print("Incident Notification: $reportMessage");
    }
  }

  void _listenToSosRequests() {
    FirebaseFirestore.instance
        .collection('sosreqs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      print("SOS Listener triggered with ${snapshot.docs.length} documents.");
      for (var doc in snapshot.docs) {
        _processSosRequest(doc);
      }
    });
  }

  void _processSosRequest(QueryDocumentSnapshot doc) {
    String sosUserId = doc['userId'];
    Timestamp sosTimestamp = doc['timestamp'];

    if (currentUserUid == null) {
      print("Current user UID is null, skipping SOS processing.");
      return;
    }

    // Skip notifications for the current user's SOS requests
    if (sosUserId == currentUserUid) {
      print("Skipping SOS for current user's request.");
      return;
    }

    String sosMessage = "Someone Needs Help!";

    if (latestSosTimestamp == null ||
        sosTimestamp.toDate().isAfter(latestSosTimestamp!)) {
      updateNotificationBar(sosMessage, sosTimestamp.toDate());
      latestSosTimestamp = sosTimestamp.toDate();
      print("SOS Notification triggered: $sosMessage");
    }
  }

  void updateNotificationBar(String message, DateTime timestamp) {
    setState(() {
      showNotificationBar = true;
      notificationMessage = message;
      _vibratePhone();
    });

    // Automatically hide the notification bar after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        showNotificationBar = false;
      });
    });
  }

  Future<void> _vibratePhone() async {
    Vibration.vibrate(); // Vibrates for the default duration
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _togglePolyline(LatLng destination) async {
    if (_userLocation != null) {
      if (_isPolylineVisible) {
        // Remove the existing polyline
        setState(() {
          _polylines.clear();
          _isPolylineVisible = false;
        });
        print("Polyline removed");
      } else {
        try {
          // Calculate distance between user location and destination
          double distance = calculateDistance(_userLocation!, destination);
          print("Distance: $distance meters");

          // Skip polyline generation if the distance is too large (e.g., 100 km)
          if (distance > 100000.0) {
            // 100 km
            print(
                "Destination too far: $distance meters. Skipping polyline generation.");
            return;
          }

          // Fetch route polyline
          final points = await _getRoutePolyline(_userLocation!, destination);
          if (points.isNotEmpty) {
            setState(() {
              _polylines.add(
                Polyline(
                  polylineId: PolylineId('route'),
                  points: points,
                  color: Colors.blue,
                  width: 5,
                ),
              );
              _isPolylineVisible =
                  true; // Update the state to show the polyline
              print('Polyline added: $points');
            });
          } else {
            print('No points to add to polyline');
          }
        } catch (e) {
          print('Error fetching route: $e');
        }
      }
    }
  }

  // Function to get the nearest hospital
  Future<LatLng> getNearestHospital(LatLng userLocation) async {
    var hospitalData =
        await FirebaseFirestore.instance.collection('hospitals').get();

    LatLng nearest = LatLng(0, 0); // Default value
    double minDistance = double.infinity;

    for (var doc in hospitalData.docs) {
      double hospitalLat = doc['latitude'];
      double hospitalLng = doc['longitude'];
      LatLng hospitalLocation = LatLng(hospitalLat, hospitalLng);

      // Calculate distance from user location to hospital
      double distance = Geolocator.distanceBetween(userLocation.latitude,
          userLocation.longitude, hospitalLat, hospitalLng);

      if (distance < minDistance) {
        minDistance = distance;
        nearest = hospitalLocation;
      }
    }

    return nearest;
  }

  Future<LatLng> getNearestEvacCenter(LatLng userLocation) async {
    var evacData = await FirebaseFirestore.instance.collection('evacs').get();

    if (evacData.docs.isEmpty) {
      print("No evacuation centers found.");
      return LatLng(0, 0);
    }

    LatLng nearest =
        LatLng(0, 0); // Default value for nearest evacuation center
    double minDistance = double
        .infinity; // Initialize the minimum distance to a very large number

    // Loop through each evacuation center document to find the nearest one
    for (var doc in evacData.docs) {
      try {
        // Ensure we are getting valid latitude and longitude values
        double evacLat = doc['latitude'];
        double evacLng = doc['longitude'];

        // Check if the latitude and longitude are valid numbers
        if (evacLat != null && evacLng != null) {
          LatLng evacLocation = LatLng(evacLat, evacLng);

          // Calculate distance from the user's location to the evacuation center
          double distance = Geolocator.distanceBetween(
              userLocation.latitude, userLocation.longitude, evacLat, evacLng);

          // If the calculated distance is shorter than the current minimum, update the nearest location
          if (distance < minDistance) {
            minDistance = distance;
            nearest = evacLocation;
          }
        } else {
          print(
              "Invalid latitude or longitude in evac center document: ${doc.id}");
        }
      } catch (e) {
        print("Error processing document ${doc.id}: $e");
      }
    }

    // After checking all evacuation centers, return the nearest one
    print("Nearest Evacuation Center: $nearest, Distance: $minDistance meters");
    return nearest;
  }

  // * polyline function
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

  Future<List<LatLng>> _getRoutePolyline(
      LatLng origin, LatLng destination) async {
    final apiKey =
        '5b3ce3597851110001cf6248f5681182c98e46e09350c1b3e224d59a'; // Replace with your ORS API key

    // Log the request URL for debugging
    final url =
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${origin.longitude},${origin.latitude}&end=${destination.longitude},${destination.latitude}';
    print("Request URL: $url");

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> coordinates =
          data['features'][0]['geometry']['coordinates'];

      // Decode ORS polyline format to LatLng list
      final List<LatLng> points = coordinates.map((coord) {
        return LatLng(
            coord[1],
            coord[
                0]); // Reverse the order from [longitude, latitude] to [latitude, longitude]
      }).toList();

      print('Decoded points: $points'); // Debugging statement
      return points;
    } else {
      print('Failed to load route: ${response.statusCode}');
      print('Response body: ${response.body}'); // Log the response body
      throw Exception('Failed to load route');
    }
  }

  double calculateDistance(LatLng origin, LatLng destination) {
    return Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );
  }

//* other functions
  void customMarker() {
    // * CRIME MARKER
    BitmapDescriptor.asset(const ImageConfiguration(size: Size(48, 48)),
            "assets/images/crimes.png")
        .then((icon) {
      setState(() {
        customIcon = icon;
      });
    });
  }

  Future<void> getCurrentLocation() async {
    if (!await checkServicePermission()) {
      return;
    }

    // * Get the initial position
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _userLocation =
          LatLng(position.latitude, position.longitude); // Update _userLocation
    });
    _updateMapPosition(position,
        smoothMove: false); // No animation for initial position

    // * Listen to position updates in real-time
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position newPosition) {
      _updateMapPosition(newPosition,
          smoothMove: true); // Apply smooth movement
    });
  }

  void _updateMapPosition(Position position, {bool smoothMove = false}) {
    // Update the camera position
    CameraPosition cameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 15,
    );

    if (smoothMove) {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition), // Smooth animation
      );
    } else {
      mapController.moveCamera(
        CameraUpdate.newCameraPosition(
            cameraPosition), // Instant move for initial position
      );
    }
  }

  Future<bool> checkServicePermission() async {
    bool isEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location Service is Disabled")));
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Location Permission is Denied. Please allow the permission to use the app.")));
      return false;
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Location Permission is permanently denied. Please change it in settings.")));
      return false;
    }
    return true;
  }

  Future<void> fetchMarkers() async {
    try {
      // Fetch data from all collections
      QuerySnapshot crimeSnapshot =
          await FirebaseFirestore.instance.collection('crimes').get();
      QuerySnapshot floodSnapshot =
          await FirebaseFirestore.instance.collection('floods').get();
      QuerySnapshot evacSnapshot =
          await FirebaseFirestore.instance.collection('evacs').get();
      QuerySnapshot hospitalSnapshot =
          await FirebaseFirestore.instance.collection('hospitals').get();
      QuerySnapshot stationSnapshot =
          await FirebaseFirestore.instance.collection('police_stations').get();

      _markers.clear();
      _crimes = crimeSnapshot.docs; // Save the crime documents
      _floods = floodSnapshot.docs; // Save the flood documents
      _evacs = evacSnapshot.docs; // Save the evacuation documents
      _hospitals = hospitalSnapshot.docs;
      _stations = stationSnapshot.docs;

      // Add crime markers
      for (var doc in crimeSnapshot.docs) {
        _addCrimeMarker(doc);
      }

      // Add flood markers
      for (var doc in floodSnapshot.docs) {
        _addFloodMarker(doc);
      }

      // Add evacuation markers
      for (var doc in evacSnapshot.docs) {
        _addEvacMarker(doc);
      }

      for (var doc in hospitalSnapshot.docs) {
        _addHospitalMarker(doc);
      }
      for (var doc in stationSnapshot.docs) {
        _addStationMarker(doc);
      }

      setState(() {});
    } catch (e) {
      print('Error loading markers: $e');
    }
  }

  void _addCrimeMarker(QueryDocumentSnapshot doc) {
    print('Document data: ${doc.data()}');
    double latitude = double.tryParse(doc['latitude'].toString()) ?? 0.0;
    double longitude = double.tryParse(doc['longitude'].toString()) ?? 0.0;

    // Log the latitude and longitude for debugging
    print('Adding crime marker at latitude: $latitude, longitude: $longitude');

    String formattedDate;
    if (doc['date'] is Timestamp) {
      DateTime dateTime = (doc['date'] as Timestamp).toDate();
      formattedDate = DateFormat('MMMM d, y h:mm a').format(dateTime);
    } else {
      formattedDate = doc['date'];
    }

    FirebaseFirestore.instance.collection('crimes').get().then((snapshot) {
      for (var doc in snapshot.docs) {
        if (!doc.data().containsKey('date')) {
          doc.reference.update({
            'date': FieldValue.serverTimestamp()
          }); // or use any default timestamp
        }
      }
    });

    LatLng markerPosition = LatLng(latitude, longitude);
    BitmapDescriptor markerIcon =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

    if (_selectedCollection == 'crimes' || _selectedCollection == null) {
      _markers.add(Marker(
        markerId: MarkerId('crime_${doc.id}'),
        position: markerPosition,
        icon: markerIcon,
        infoWindow: InfoWindow(
          title: "Crime",
          snippet: doc['type'],
          onTap: () {
            _showDetailsScreen(doc['type'], doc, formattedDate);
          },
        ),
      ));
    }

    // Log the total number of markers added
    print('Total markers added: ${_markers.length}');
  }

  void _addFloodMarker(QueryDocumentSnapshot doc) {
    print('Document data: ${doc.data()}');
    double latitude = double.tryParse(doc['latitude'].toString()) ?? 0.0;
    double longitude = double.tryParse(doc['longitude'].toString()) ?? 0.0;

    // Log the latitude and longitude for debugging
    print('Adding flood marker at latitude: $latitude, longitude: $longitude');

    String formattedDate;
    if (doc['date'] is Timestamp) {
      DateTime dateTime = (doc['date'] as Timestamp).toDate();
      formattedDate = DateFormat('MMMM d, y h:mm a').format(dateTime);
    } else {
      formattedDate = doc['date'];
    }

    FirebaseFirestore.instance.collection('floods').get().then((snapshot) {
      for (var doc in snapshot.docs) {
        if (!doc.data().containsKey('date')) {
          doc.reference.update({
            'date': FieldValue.serverTimestamp()
          }); // or use any default timestamp
        }
      }
    });

    LatLng markerPosition = LatLng(latitude, longitude);
    BitmapDescriptor markerIcon =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);

    if (_selectedCollection == 'floods' || _selectedCollection == null) {
      _markers.add(Marker(
        markerId: MarkerId('flood_${doc.id}'),
        position: markerPosition,
        icon: markerIcon,
        infoWindow: InfoWindow(
          title: doc['type'],
          onTap: () {
            _showDetailsScreen('flood', doc, formattedDate);
          },
        ),
      ));
    }

    // Log the total number of markers added
    print('Total markers added: ${_markers.length}');
  }

  void _addEvacMarker(QueryDocumentSnapshot doc) {
    double latitude = double.tryParse(doc['latitude'].toString()) ?? 0.0;
    double longitude = double.tryParse(doc['longitude'].toString()) ?? 0.0;

    // Log the latitude and longitude for debugging
    print(
        'Adding evacuation marker at latitude: $latitude, longitude: $longitude');

    LatLng markerPosition = LatLng(latitude, longitude);
    BitmapDescriptor markerIcon =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

    if (_selectedCollection == 'evacs' || _selectedCollection == null) {
      _markers.add(Marker(
        markerId: MarkerId('evac_${doc.id}'),
        position: markerPosition,
        icon: markerIcon,
        infoWindow: InfoWindow(title: doc['type'], snippet: doc["name"]),
      ));
    }

    // Log the total number of markers added
    print('Total markers added: ${_markers.length}');
  }

  void _addHospitalMarker(QueryDocumentSnapshot doc) {
    double latitude = double.tryParse(doc['latitude'].toString()) ?? 0.0;
    double longitude = double.tryParse(doc['longitude'].toString()) ?? 0.0;

    // Log the latitude and longitude for debugging
    print(
        'Adding evacuation marker at latitude: $latitude, longitude: $longitude');

    LatLng markerPosition = LatLng(latitude, longitude);
    BitmapDescriptor markerIcon =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);

    if (_selectedCollection == 'hospitals' || _selectedCollection == null) {
      _markers.add(Marker(
        markerId: MarkerId('hospital_${doc.id}'),
        position: markerPosition,
        icon: markerIcon,
        infoWindow: InfoWindow(title: doc['type'], snippet: doc["name"]),
      ));
    }

    // Log the total number of markers added
    print('Total markers added: ${_markers.length}');
  }

  void _addStationMarker(QueryDocumentSnapshot doc) {
    double latitude = double.tryParse(doc['latitude'].toString()) ?? 0.0;
    double longitude = double.tryParse(doc['longitude'].toString()) ?? 0.0;

    // Log the latitude and longitude for debugging
    print(
        'Adding evacuation marker at latitude: $latitude, longitude: $longitude');

    LatLng markerPosition = LatLng(latitude, longitude);
    BitmapDescriptor markerIcon =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);

    if (_selectedCollection == 'police_stations' ||
        _selectedCollection == null) {
      _markers.add(Marker(
        markerId: MarkerId('stations_${doc.id}'),
        position: markerPosition,
        icon: markerIcon,
        infoWindow: InfoWindow(title: doc['type'], snippet: doc["name"]),
      ));
    }

    // Log the total number of markers added
    print('Total markers added: ${_markers.length}');
  }

  void _showDetailsScreen(
      String crimeType, QueryDocumentSnapshot doc, String formattedDate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsScreen(
          type: crimeType,
          details: doc['details'] ?? '',
          latitude: doc['latitude'],
          longitude: doc['longitude'],
          brgy: doc['brgy'] ?? '',
          date: formattedDate,
        ),
      ),
    );
  }

  void _onItemTap(QueryDocumentSnapshot doc) {
    // Get the position of the tapped item
    LatLng position = LatLng(doc['latitude'], doc['longitude']);

    mapController.animateCamera(CameraUpdate.newLatLng(position));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            myLocationEnabled: true,
            initialCameraPosition: const CameraPosition(
              target: LatLng(14.5995, 120.9842),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            polygons: polygons,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
              fetchMarkers();
            },
          ),
          if (showNotificationBar)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.blueAccent,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        notificationMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          showNotificationBar = false;
                          notificationMessage = "";
                        });

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SlidingUpPanel(
            controller: _panelController,
            minHeight: 150,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            panel: _buildSlidingPanel(),
          ),
          Positioned(
            top: 80,
            right: 10,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        showIndicator = false;
                      });

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.notifications,
                      size: 30,
                      color: Colors.blue,
                    ),
                  ),
                ),
                if (showIndicator)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 140,
            right: 10,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Column(
                children: [
                  IconButton(
                    onPressed: () async {
                      if (_userLocation != null) {
                        LatLng nearestEvacCenter =
                            await getNearestEvacCenter(_userLocation!);
                        print("Nearest Evac Center: $nearestEvacCenter");
                        await _togglePolyline(nearestEvacCenter);
                      } else {
                        print("User location is null.");
                      }
                    },
                    icon: const Icon(
                      Icons.house,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: 10,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Column(
                children: [
                  IconButton(
                    onPressed: () async {
                      if (_userLocation != null) {
                        LatLng nearestHospital =
                            await getNearestHospital(_userLocation!);
                        print("Nearest Hospital: $nearestHospital");
                        await _togglePolyline(nearestHospital);
                      } else {
                        print("User location is null.");
                      }
                    },
                    icon: const Icon(
                      Icons.local_hospital,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlidingPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Gap(10),
          Container(
            width: 30,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const Gap(10),
          const Center(
            child: Text(
              "Information",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const Gap(10),
          ToggleButtons(
            direction: Axis.vertical,
            isSelected: [
              _selectedCollection == 'crimes',
              _selectedCollection == 'floods',
              _selectedCollection == 'evacs',
              _selectedCollection == 'hospitals',
              _selectedCollection == 'police_stations',
              _selectedCollection == null,
            ],
            onPressed: (int index) async {
              setState(() {
                if (index == 0) {
                  _selectedCollection = 'crimes';
                } else if (index == 1) {
                  _selectedCollection = 'floods';
                } else if (index == 2) {
                  _selectedCollection = 'evacs';
                } else if (index == 3) {
                  _selectedCollection = 'hospitals';
                } else if (index == 4) {
                  _selectedCollection = 'police_stations';
                } else {
                  _selectedCollection = null;
                }
              });

              fetchMarkers();

              if (_selectedCollection == 'crimes' ||
                  _selectedCollection == null) {
                setState(() {
                  isLoading = true;
                });
                await _fetchPolygonsWithCrimeData();
              } else {
                setState(() {
                  polygons = {};
                });
              }
            },
            borderRadius: BorderRadius.circular(20),
            selectedColor: Colors.white,
            fillColor: Colors.blue,
            color: Colors.black,
            constraints: BoxConstraints(
              minHeight: 40.0,
              minWidth: (MediaQuery.of(context).size.width - 46) / 5.1,
            ),
            children: const [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gavel, size: 18),
                  SizedBox(width: 3),
                  Text("Crimes"),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flood_outlined, size: 18),
                  SizedBox(width: 3),
                  Text("Floods"),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.house_outlined, size: 18),
                  SizedBox(width: 3),
                  Text("Evacuation Centers"),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_hospital, size: 18),
                  SizedBox(width: 3),
                  Text("Hospitals"),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_police_rounded, size: 18),
                  SizedBox(width: 3),
                  Text("Police Station"),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list, size: 18),
                  SizedBox(width: 3),
                  Text("All"),
                ],
              ),
            ],
          ),
          const Gap(10),
          Expanded(
            child: ListView.builder(
              itemCount: _selectedCollection == 'crimes'
                  ? _crimes.length
                  : _selectedCollection == 'floods'
                      ? _floods.length
                      : _selectedCollection == 'evacs'
                          ? _evacs.length
                          : _selectedCollection == 'hospitals'
                              ? _hospitals.length
                              : _selectedCollection == 'police_stations'
                                  ? _stations.length
                                  : _crimes.length +
                                      _floods.length +
                                      _evacs.length +
                                      _hospitals.length +
                                      _stations.length,
              itemBuilder: (context, index) {
                dynamic doc;
                bool isCrime = false;
                bool isFlood = false;
                bool isEvac = false;
                bool isHospital = false;
                bool isPolice = false;

                if (_selectedCollection == 'crimes') {
                  if (index < _crimes.length) {
                    doc = _crimes[index];
                    isCrime = true;
                  }
                } else if (_selectedCollection == 'floods') {
                  if (index < _floods.length) {
                    doc = _floods[index];
                    isFlood = true;
                  }
                } else if (_selectedCollection == 'evacs') {
                  if (index < _evacs.length) {
                    doc = _evacs[index];
                    isEvac = true;
                  }
                } else if (_selectedCollection == 'hospitals') {
                  if (index < _hospitals.length) {
                    doc = _hospitals[index];
                    isHospital = true;
                  }
                } else if (_selectedCollection == 'police_stations') {
                  if (index < _stations.length) {
                    doc = _stations[index];
                    isPolice = true;
                  }
                } else {
                  if (index < _crimes.length) {
                    doc = _crimes[index];
                    isCrime = true;
                  } else if (index < _crimes.length + _floods.length) {
                    int floodIndex = index - _crimes.length;
                    doc = _floods[floodIndex];
                    isFlood = true;
                  } else if (index <
                      _crimes.length + _floods.length + _evacs.length) {
                    int evacIndex = index - _crimes.length - _floods.length;
                    doc = _evacs[evacIndex];
                    isEvac = true;
                  } else if (index <
                      _crimes.length +
                          _floods.length +
                          _evacs.length +
                          _hospitals.length) {
                    int hospitalIndex =
                        index - _crimes.length - _floods.length - _evacs.length;
                    doc = _hospitals[hospitalIndex];
                    isHospital = true;
                  } else {
                    int stationsIndex = index -
                        _crimes.length -
                        _floods.length -
                        _evacs.length -
                        _hospitals.length;
                    doc = _stations[stationsIndex];
                    isPolice = true;
                  }
                }

                if (doc != null) {
                  return GestureDetector(
                    onTap: () {
                      _showpins(doc);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCrime
                              ? Colors.red.shade200
                              : isFlood
                                  ? Colors.blue.shade200
                                  : isEvac
                                      ? Colors.green.shade200
                                      : Colors.purple.shade600,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        title: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: isCrime
                                    ? Colors.red
                                    : isFlood
                                        ? Colors.blue
                                        : isEvac
                                            ? Colors.green
                                            : isHospital
                                                ? Colors.orange
                                                : Colors.purple.shade600,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                                child: Text(isEvac
                                    ? doc['name']
                                    : isHospital
                                        ? doc['name']
                                        : isPolice
                                            ? doc['name']
                                            : doc['type'] ?? '')),
                          ],
                        ),
                        subtitle: Text(isEvac
                            ? "Location: ${doc['latitude']}, ${doc['longitude']}"
                            : isHospital
                                ? "Location: ${doc['latitude']}, ${doc['longitude']}"
                                : isPolice
                                    ? "Location: ${doc['latitude']}, ${doc['longitude']}"
                                    : doc['brgy']),
                        trailing: IconButton(
                          onPressed: () {
                            _onItemTap(doc);
                          },
                          icon: const Icon(Icons.arrow_right_alt_rounded),
                        ),
                      ),
                    ),
                  );
                }

                return Container();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showpins(dynamic doc) {
    double latitude = doc['latitude'];
    double longitude = doc['longitude'];

    _updateMap(latitude, longitude);
  }

  void _updateMap(double latitude, double longitude) {
    _moveToMarker(LatLng(latitude, longitude));
  }

  void _moveToMarker(LatLng position) {
    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: position,
      zoom: 15,
    )));
  }
}
