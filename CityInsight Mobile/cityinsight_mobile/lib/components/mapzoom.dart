import 'package:google_maps_flutter/google_maps_flutter.dart';

class CameraState {
  static CameraPosition? _cameraPosition;

  static CameraPosition? get cameraPosition => _cameraPosition;

  static set cameraPosition(CameraPosition? position) {
    _cameraPosition = position;
  }
}
