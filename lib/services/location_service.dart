import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
class LocationService {

  static Position? _lastKnown;
  static String? _lastError;

  static Position? get lastKnownPosition => _lastKnown;
  static String? get lastError => _lastError;

  // Get GPS Location
  static Future<Position?> initialize() async {
    try {
      _lastError = null;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _lastError = "Location services are disabled";
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _lastError = "Location permission denied";
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _lastError = "Location permission permanently denied";
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _lastKnown = position;
      return position;

    } catch (e) {
      _lastError = "Failed to get location";
      return null;
    }
  }

  // Refresh location
  static Future<Position?> refresh() async {
    return initialize();
  }

  // Convert lat/lng to real address
  static Future<String?> getAddressFromPosition(Position pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isEmpty) return null;

      final p = placemarks.first;

      return "${p.street}, ${p.locality}, ${p.administrativeArea}, ${p.country}";
    } catch (e) {
      return null;
    }
  }


  // Save location to Supabase database
  static Future<void> saveToDatabase({
  required Position pos,
  String? address,
  required String userId,
}) async {
  final supabase = Supabase.instance.client;

  try {
    final res = await supabase.from('user_location').upsert({
      'user_id': userId, // use the parameter you pass in
      'lat': pos.latitude,
      'lng': pos.longitude, //  must match your DB column name: lng
      'address': address,
      'accuracy': pos.accuracy,
      'updated_at': DateTime.now().toIso8601String(),
    }).select();

    debugPrint(" saved location: $res");
  } catch (e) {
    debugPrint("save location error: $e");
    rethrow;
  }
}

}