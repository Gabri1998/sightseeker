import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import '../models/attraction.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../screens/attraction_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late gmaps.GoogleMapController _mapController;
  late final LocationService _locationService;
  late final PlacesService _placesService;
  List<Attraction> _attractions = [];
  gmaps.LatLng? _currentLocation;
  bool _isLoading = true;
  String? _errorMessage;
  final Set<gmaps.Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    _placesService = PlacesService(dotenv.get('GOOGLE_MAPS_API_KEY'));
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final position = await _locationService.getCurrentPosition();
      setState(() {
        _currentLocation = gmaps.LatLng(position.latitude, position.longitude);
      });

      await _loadAttractions(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize: ${e.toString()}';
      });
      _showErrorSnackbar(_errorMessage!);
    }
  }

  Future<void> _loadAttractions(double lat, double lng) async {
    try {
      final attractions = await _placesService.fetchNearbyAttractions(lat, lng);
      setState(() {
        _attractions = attractions;
        _isLoading = false;
      });
      _zoomToFitMarkers();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load attractions: ${e.toString()}';
      });
      _showErrorSnackbar(_errorMessage!);
    }
  }

  void _zoomToFitMarkers() {
    if (_mapController == null || _attractions.isEmpty || _currentLocation == null) return;

    final bounds = _attractions.fold<gmaps.LatLngBounds>(
      gmaps.LatLngBounds(
        northeast: _currentLocation!,
        southwest: _currentLocation!,
      ),
          (bounds, attraction) {
        final latLng = gmaps.LatLng(attraction.latitude, attraction.longitude);
        return gmaps.LatLngBounds(
          northeast: gmaps.LatLng(
            max(bounds.northeast.latitude, latLng.latitude),
            max(bounds.northeast.longitude, latLng.longitude),
          ),
          southwest: gmaps.LatLng(
            min(bounds.southwest.latitude, latLng.latitude),
            min(bounds.southwest.longitude, latLng.longitude),
          ),
        );
      },
    );

    _mapController.animateCamera(
      gmaps.CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  Future<void> _showDirections(Attraction attraction) async {
    try {
      final currentPos = await _locationService.getCurrentPosition();
      final currentLatLng = gmaps.LatLng(currentPos.latitude, currentPos.longitude);
      final destinationLatLng = gmaps.LatLng(
          attraction.latitude,
          attraction.longitude
      );

      setState(() {
        _polylines.clear();
        _polylines.add(gmaps.Polyline(
          polylineId: gmaps.PolylineId(attraction.id),
          color: Colors.blue,
          width: 5,
          points: [currentLatLng, destinationLatLng],
        ));
      });

      _mapController.animateCamera(
        gmaps.CameraUpdate.newLatLngBounds(
          gmaps.LatLngBounds(
            northeast: gmaps.LatLng(
              max(currentLatLng.latitude, destinationLatLng.latitude),
              max(currentLatLng.longitude, destinationLatLng.longitude),
            ),
            southwest: gmaps.LatLng(
              min(currentLatLng.latitude, destinationLatLng.latitude),
              min(currentLatLng.longitude, destinationLatLng.longitude),
            ),
          ),
          100,
        ),
      );
    } catch (e) {
      _showErrorSnackbar('Failed to show directions: ${e.toString()}');
    }
  }

  Future<void> _openMapsDirections(Attraction attraction) async {
    try {
      final currentPos = await _locationService.getCurrentPosition();
      final uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1'
              '&origin=${currentPos.latitude},${currentPos.longitude}'
              '&destination=${attraction.latitude},${attraction.longitude}'
              '&travelmode=walking'
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not launch maps');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to open maps: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onMapCreated(gmaps.GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      final latLng = gmaps.LatLng(position.latitude, position.longitude);
      _mapController.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(latLng, 15),
      );
    } catch (e) {
      _showErrorSnackbar('Failed to get current location: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initializeApp,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Attractions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToCurrentLocation,
            tooltip: 'Current location',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadAttractions(
              _currentLocation?.latitude ?? 0,
              _currentLocation?.longitude ?? 0,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          gmaps.GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: gmaps.CameraPosition(
              target: _currentLocation ?? const gmaps.LatLng(0, 0),
              zoom: 14,
            ),
            markers: _buildMarkers(),
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Set<gmaps.Marker> _buildMarkers() {
    return {
      if (_currentLocation != null)
        gmaps.Marker(
          markerId: const gmaps.MarkerId('currentLocation'),
          position: _currentLocation!,
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueBlue,
          ),
          infoWindow: const gmaps.InfoWindow(title: 'Your Location'),
        ),
      ..._attractions.map((a) => gmaps.Marker(
        markerId: gmaps.MarkerId(a.id),
        position: gmaps.LatLng(a.latitude, a.longitude),
        infoWindow: gmaps.InfoWindow(
          title: a.name,
          snippet: '${a.distanceKm?.toStringAsFixed(1)} km away',
        ),
        onTap: () {
          // Show directions when marker is tapped
          _showDirections(a);

          // Show bottom sheet with options
          _showAttractionOptions(a);
        },
      )),
    };
  }

  void _showAttractionOptions(Attraction attraction) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                attraction.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openMapsDirections(attraction);
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Open in Google Maps'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
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
                  icon: const Icon(Icons.info_outline),
                  label: const Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

double max(double a, double b) => a > b ? a : b;
double min(double a, double b) => a < b ? a : b;