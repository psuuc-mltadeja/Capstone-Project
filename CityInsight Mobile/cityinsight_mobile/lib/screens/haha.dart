import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// Function to decode encoded polyline
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

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LatLng _currentLocation =
      LatLng(15.996873025613311, 120.42085240900845); // Parking location
  LatLng? _userLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final double _zoomLevel = 17.0;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        print('Location permissions are denied.');
        return;
      }
    }

    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _addMarker();
        _addPolyline();
        _updateCamera();
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  // Ensure this method is properly defined in your class open route services
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
      throw Exception('Failed to load route');
    }
  }

  void _addMarker() {
    if (mapController != null) {
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId('current_location'),
            position: _currentLocation,
            infoWindow: InfoWindow(
              title: 'Parking Location',
            ),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );

        if (_userLocation != null) {
          _markers.add(
            Marker(
              markerId: MarkerId('user_location'),
              position: _userLocation!,
              infoWindow: InfoWindow(
                title: 'Your Location',
                snippet: 'You are here',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
            ),
          );
        }
      });
    }
  }

  Future<void> _addPolyline() async {
    if (_userLocation != null) {
      try {
        final points =
            await _getRoutePolyline(_userLocation!, _currentLocation);
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
            print('Polyline added: $points'); // Debugging statement
          });
        } else {
          print('No points to add to polyline');
        }
      } catch (e) {
        print('Error fetching route: $e');
      }
    }
  }

  void _updateCamera() {
    if (mapController != null && _userLocation != null) {
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          math.min(_userLocation!.latitude, _currentLocation.latitude),
          math.min(_userLocation!.longitude, _currentLocation.longitude),
        ),
        northeast: LatLng(
          math.max(_userLocation!.latitude, _currentLocation.latitude),
          math.max(_userLocation!.longitude, _currentLocation.longitude),
        ),
      );

      mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50), // Adjust padding as needed
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parking Route Map'),
      ),
      body: GoogleMap(
        onMapCreated: (controller) {
          mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: _currentLocation,
          zoom: _zoomLevel,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers,
        polylines: _polylines,
      ),
    );
  }
}
