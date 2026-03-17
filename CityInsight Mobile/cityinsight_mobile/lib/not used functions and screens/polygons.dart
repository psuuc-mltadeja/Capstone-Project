import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as map_tool;

class MapWithRealLocation extends StatefulWidget {
  const MapWithRealLocation({super.key});

  @override
  State<MapWithRealLocation> createState() => _MapWithRealLocationState();
}

class _MapWithRealLocationState extends State<MapWithRealLocation> {
  static const initialPosition = LatLng(15.987770817221056, 120.57319298046644);
  late GoogleMapController mapController;

  Set<Polygon> polygons = {};
  Map<String, int> crimeCounts = {};
  bool isLoading = true;
  String? currentZone;
  bool hasShownModal = false;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Map with Real-Time Tracking"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              initialCameraPosition:
                  const CameraPosition(target: initialPosition, zoom: 12),
              polygons: polygons,
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
            ),
    );
  }
}
