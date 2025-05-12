import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  final String apiKey;
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  GeocodingService(this.apiKey);

  Future<Map<String, dynamic>> geocodeAddress(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url = '$_baseUrl?address=$encodedAddress&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data;
        }
        throw Exception(data['error_message'] ?? 'Geocoding failed');
      }
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    } catch (e) {
      throw Exception('Geocoding service error: $e');
    }
  }

  Future<Map<String, dynamic>> reverseGeocode(double lat, double lng) async {
    final url = '$_baseUrl?latlng=$lat,$lng&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data;
        }
        throw Exception(data['error_message'] ?? 'Reverse geocoding failed');
      }
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    } catch (e) {
      throw Exception('Reverse geocoding error: $e');
    }
  }
}