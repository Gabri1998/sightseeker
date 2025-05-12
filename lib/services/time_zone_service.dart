import 'dart:convert';
import 'package:http/http.dart' as http;

class TimeZoneService {
  final String apiKey;
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/timezone/json';

  TimeZoneService(this.apiKey);

  Future<Map<String, dynamic>> fetchTimeZone(double latitude, double longitude,
      [int? timestamp]) async {
    final ts = timestamp ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final url = '$_baseUrl?location=$latitude,$longitude&timestamp=$ts&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return {
            'timeZoneId': data['timeZoneId'],
            'timeZoneName': data['timeZoneName'],
            'rawOffset': data['rawOffset'],
            'dstOffset': data['dstOffset'],
          };
        }
        throw Exception(data['errorMessage'] ?? 'Failed to get time zone');
      }
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    } catch (e) {
      throw Exception('Time zone service error: $e');
    }
  }
}