import 'package:flutter_dotenv/flutter_dotenv.dart';

class Attraction {
  final String id;
  final String name;
  final String description;
  final double distanceKm;
  final double latitude;
  final double longitude;
  final double? rating;
  final Uri? photoUrl;
  final String? placeId;
  final String? detailedDescription;  // New field for enhanced descriptions
  final String? website;             // New field
  final List<String>? types;         // New field

  Attraction({
    required this.id,
    required this.name,
    required this.description,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
    this.rating,
    this.photoUrl,
    this.placeId,
    this.detailedDescription,
    this.website,
    this.types,
  });

  // Enhanced copyWith method with new fields
  Attraction copyWith({
    String? id,
    String? name,
    String? description,
    double? distanceKm,
    double? latitude,
    double? longitude,
    double? rating,
    Uri? photoUrl,
    String? placeId,
    String? detailedDescription,
    String? website,
    List<String>? types,
  }) {
    return Attraction(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      distanceKm: distanceKm ?? this.distanceKm,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      photoUrl: photoUrl ?? this.photoUrl,
      placeId: placeId ?? this.placeId,
      detailedDescription: detailedDescription ?? this.detailedDescription,
      website: website ?? this.website,
      types: types ?? this.types,
    );
  }

  // Enhanced factory constructor with additional fields
  factory Attraction.fromPlace(Map<String, dynamic> place) {
    final geo = place['geometry']['location'];
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

    // Handle photo URL
    Uri? photoUrl;
    if (place['photos'] != null && place['photos'].isNotEmpty) {
      photoUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/photo'
              '?maxwidth=800'
              '&photoreference=${place['photos'][0]['photo_reference']}'
              '&key=$apiKey'
      );
    }

    // Handle types
    final List<String>? types = place['types'] != null
        ? List<String>.from(place['types'])
        : null;

    return Attraction(
      id: place['place_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: place['name'] ?? 'Unnamed Attraction',
      description: place['vicinity'] ?? 'No description available',
      distanceKm: 0, // Will be calculated later
      latitude: geo['lat'].toDouble(),
      longitude: geo['lng'].toDouble(),
      rating: place['rating']?.toDouble(),
      photoUrl: photoUrl,
      placeId: place['place_id'],
      types: types,
    );
  }

  // New factory constructor for detailed places
  factory Attraction.fromDetailedPlace(Map<String, dynamic> placeDetails) {
    final attraction = Attraction.fromPlace(placeDetails);
    return attraction.copyWith(
      detailedDescription: placeDetails['description'] ??
          placeDetails['editorial_summary']?['overview'],
      website: placeDetails['website'],
    );
  }

  // Helper method to get the best available description
  String get displayDescription {
    return detailedDescription ?? description;
  }

  // Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'distanceKm': distanceKm,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'photoUrl': photoUrl?.toString(),
      'placeId': placeId,
      'detailedDescription': detailedDescription,
      'website': website,
      'types': types,
    };
  }
}