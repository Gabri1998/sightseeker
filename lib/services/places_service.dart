import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/attraction.dart';

class PlacesService {
  final String apiKey;
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const double _maxDistanceKm = 20.0;

  PlacesService(this.apiKey);

  Future<List<Attraction>> fetchNearbyAttractions(
      double latitude,
      double longitude, {
        String? nextPageToken,
        String language = 'en',
      }) async {
    final url = '$_baseUrl/nearbysearch/json?'
        'location=$latitude,$longitude'
        '&radius=20000' // 20km in meters
        '&type=tourist_attraction'
        '&language=$language'
        '${nextPageToken != null ? '&pagetoken=$nextPageToken' : ''}'
        '&key=$apiKey';

    debugPrint('Fetching nearby attractions from: $url');
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final places = data['results'] as List;

          final attractions = await Future.wait(
            places.map((place) async {
              var attraction = Attraction.fromPlace(place);
              final distance = await Geolocator.distanceBetween(
                latitude, longitude,
                attraction.latitude, attraction.longitude,
              ) / 1000; // Convert to km

              // Fetch additional details if placeId is available
              if (attraction.placeId != null) {
                try {
                  final details = await getPlaceDetails(attraction.placeId!, language: language);
                  final enhancedDescription = details['description'] ??
                      details['editorial_summary']?['overview'] ??
                      attraction.description;

                  // Use copyWith to create a new instance with updated description
                  attraction = attraction.copyWith(
                    description: enhancedDescription,
                    distanceKm: distance,
                  );
                } catch (e) {
                  debugPrint('Failed to fetch details for ${attraction.name}: $e');
                  // Still update distance even if details fail
                  attraction = attraction.copyWith(
                    distanceKm: distance,
                  );
                }
              } else {
                // Update distance if no placeId
                attraction = attraction.copyWith(
                  distanceKm: distance,
                );
              }

              return attraction;
            }),
          );

          return attractions.where((a) => a.distanceKm <= _maxDistanceKm).toList();
        }
        throw Exception(data['error_message'] ?? 'Failed to fetch places');
      }
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    } catch (e) {
      debugPrint('Error fetching nearby attractions: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPlaceDetails(
      String placeId, {
        String language = 'en',
        List<String> fields = const [
          'name',
          'formatted_address',
          'geometry',
          'rating',
          'photos',
          'types',
          'website',
          'editorial_summary',
          'description'
        ],
      }) async {
    final fieldsParam = fields.join(',');
    final url = '$_baseUrl/details/json?'
        'place_id=$placeId'
        '&fields=$fieldsParam'
        '&language=$language'
        '&key=$apiKey';

    debugPrint('Fetching place details from: $url');
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result'] ?? {};
        }
        throw Exception(data['error_message'] ?? 'Failed to get place details');
      }
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    } catch (e) {
      debugPrint('Error fetching place details: $e');
      rethrow;
    }
  }

  Future<String?> getPhotoUrl(
      String photoReference, {
        int maxWidth = 800,
        int maxHeight = 800,
      }) async {
    final url = '$_baseUrl/photo?'
        'maxwidth=$maxWidth'
        '&maxheight=$maxHeight'
        '&photo_reference=$photoReference'
        '&key=$apiKey';

    return url;
  }
}