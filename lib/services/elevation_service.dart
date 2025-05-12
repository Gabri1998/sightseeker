import 'dart:convert';
import 'package:http/http.dart' as http;

class ElevationService {
  final String apiKey;
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/elevation/json';

  ElevationService(this.apiKey);

  Future<double> fetchElevation(double latitude, double longitude) async {
    final url = '$_baseUrl?locations=$latitude,$longitude&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['elevation']?.toDouble() ?? 0.0;
        }
        throw Exception(data['error_message'] ?? 'Failed to get elevation');
      }
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    } catch (e) {
      throw Exception('Elevation service error: $e');
    }
  }
}