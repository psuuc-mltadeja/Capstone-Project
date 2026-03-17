import 'package:cityinsight_mobile/screens/details-screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as map_tool;

class CrimeMapScreen extends StatefulWidget {
  const CrimeMapScreen({super.key});

  @override
  State<CrimeMapScreen> createState() => _CrimeMapScreenState();
}

class _CrimeMapScreenState extends State<CrimeMapScreen> {
  @override
  void initState() {
    super.initState();
    fetchMarkers();
    customMarker();
    getCurrentLocation();
    _fetchPolygonsWithCrimeData();
    _startTrackingUserLocation();
  }

  BitmapDescriptor customIcon = BitmapDescriptor.defaultMarker;
  Map<String, int> crimeCounts = {};
  Set<Polygon> polygons = {};
  LatLng? _userLocation;
  List<QueryDocumentSnapshot> _crimes = [];
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  bool isLoading = true;
  String? currentZone;

  void customMarker() {
    BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      "assets/images/crimes.png",
    ).then((icon) {
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
      _userLocation = LatLng(position.latitude, position.longitude);
    });
    _updateMapPosition(position, smoothMove: false);

    // * Listen to position updates in real-time
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position newPosition) {
      _updateMapPosition(newPosition, smoothMove: true);
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
        CameraUpdate.newCameraPosition(cameraPosition),
      );
    } else {
      mapController.moveCamera(
        CameraUpdate.newCameraPosition(cameraPosition),
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

      _markers.clear();
      _crimes = crimeSnapshot.docs;

      // Add crime markers
      for (var doc in crimeSnapshot.docs) {
        _addCrimeMarker(doc);
      }

      setState(() {});
    } catch (e) {
      print('Error loading markers: $e');
    }
  }

  void _startTrackingUserLocation() {
    Geolocator.getPositionStream().listen((Position position) {
      LatLng currentLocation = LatLng(position.latitude, position.longitude);
      _checkLocationInPolygon(currentLocation);
    });
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
    BitmapDescriptor markerIcon = customIcon; // Use the custom icon

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        myLocationEnabled: true,
        initialCameraPosition: const CameraPosition(
          target: LatLng(14.5995, 120.9842),
          zoom: 15,
        ),
        markers: _markers,
        polygons: polygons,
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
          fetchMarkers();
        },
      ),
    );
  }
}
