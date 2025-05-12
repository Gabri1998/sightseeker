import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:location/location.dart' as loc;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationService {
  final GeolocatorPlatform _geolocator = GeolocatorPlatform.instance;
  final loc.Location _location = loc.Location();
  final String _apiKey = dotenv.get('GOOGLE_MAPS_API_KEY');

  Future<Position> getCurrentPosition() async {
    try {
      bool serviceEnabled = await _geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _geolocator.openLocationSettings();
        if (!serviceEnabled) {
          throw Exception('Location services are disabled');
        }
      }

      LocationPermission permission = await _geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      return await _geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception('Failed to get position: ${e.toString()}');
    }
  }

  Future<gmaps.LatLng> getCurrentLatLng() async {
    final position = await getCurrentPosition();
    return gmaps.LatLng(position.latitude, position.longitude);
  }

  Future<String> getCityName(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_apiKey'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Try to find different administrative levels
          final components = data['results'][0]['address_components'];

          // 1. Try to get locality (city)
          final city = _extractComponent(components, 'locality');
          if (city != null) return city;

          // 2. Try to get sublocality (neighborhood)
          final sublocality = _extractComponent(components, 'sublocality');
          if (sublocality != null) return sublocality;

          // 3. Try to get administrative_area_level_2 (county)
          final county = _extractComponent(components, 'administrative_area_level_2');
          if (county != null) return county;

          // 4. Try to get administrative_area_level_1 (state)
          final state = _extractComponent(components, 'administrative_area_level_1');
          if (state != null) return state;

          // 5. Fallback to formatted address
          return data['results'][0]['formatted_address'];
        }
        throw Exception(data['error_message'] ?? 'Failed to get location name');
      }
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    } catch (e) {
      throw Exception('Geocoding service error: $e');
    }
  }

  String? _extractComponent(List<dynamic> components, String type) {
    try {
      final component = components.firstWhere(
            (c) => c['types'].contains(type),
        orElse: () => null,
      );
      return component?['long_name'];
    } catch (e) {
      return null;
    }
  }

  Future<bool> isLocationEnabled() async {
    try {
      return await _location.serviceEnabled();
    } catch (e) {
      throw Exception('Failed to check location status: ${e.toString()}');
    }
  }

  Stream<loc.LocationData> getLocationStream() {
    try {
      return _location.onLocationChanged;
    } catch (e) {
      throw Exception('Failed to get location stream: ${e.toString()}');
    }
  }

  Future<bool> requestService() async {
    try {
      return await _location.requestService();
    } catch (e) {
      throw Exception('Failed to request location service: ${e.toString()}');
    }
  }

  Future<loc.PermissionStatus> checkAndRequestPermission() async {
    try {
      var status = await _location.hasPermission();
      if (status == loc.PermissionStatus.denied) {
        status = await _location.requestPermission();
      }
      return status;
    } catch (e) {
      throw Exception('Failed to check/request permissions: ${e.toString()}');
    }
  }
}