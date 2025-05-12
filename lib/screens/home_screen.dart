import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import '../models/attraction.dart';
import '../widgets/attractions_list.dart';
import '../screens/error_screen.dart';
import '../screens/attraction_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Attraction> _attractions = [];
  bool _isLoading = true;
  String? _error;
  String _cityName = 'Loading...';
  final LocationService _locationService = LocationService();
  late final PlacesService _placesService;

  @override
  void initState() {
    super.initState();
    _placesService = PlacesService(dotenv.get('GOOGLE_MAPS_API_KEY'));
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      if (_error != null) {
        await Future.delayed(const Duration(seconds: 2));
      }

      final position = await _locationService.getCurrentLatLng();
      final cityName = await _locationService.getCityName(
          position.latitude, position.longitude);

      setState(() {
        _cityName = cityName;
      });

      final attractions = await _placesService.fetchNearbyAttractions(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _attractions = attractions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return ErrorScreen(
        errorMessage: _error!,
        onRetry: _initializeApp,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SightSeeker'),
            Text(
              _cityName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeApp,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: Column(
        children: [
          // Add Welcome Banner
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to $_cityName!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Discover ${_attractions.length} attractions nearby',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          // Attractions List
          Expanded(
            child: _attractions.isEmpty
                ? const Center(child: Text('No attractions found'))
                : AttractionsList(
              attractions: _attractions,
              onAttractionSelected: (attraction) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AttractionDetailScreen(
                      attraction: attraction,
                      currentLocation: _locationService.getCurrentLatLng(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}