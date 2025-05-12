import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:url_launcher/url_launcher.dart';
import '../models/attraction.dart';
import '../services/places_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AttractionDetailScreen extends StatefulWidget {
  final Attraction attraction;
  final Future<gmaps.LatLng> currentLocation;

  const AttractionDetailScreen({
    super.key,
    required this.attraction,
    required this.currentLocation,
  });

  @override
  State<AttractionDetailScreen> createState() => _AttractionDetailScreenState();
}

class _AttractionDetailScreenState extends State<AttractionDetailScreen> {
  late gmaps.GoogleMapController _mapController;
  gmaps.LatLng? _currentLocation;
  final Set<gmaps.Marker> _markers = {};
  final Set<gmaps.Polyline> _polylines = {};
  String? _detailedDescription;
  bool _isLoadingDescription = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _fetchDetailedDescription();
  }

  Future<void> _fetchDetailedDescription() async {
    if (widget.attraction.placeId == null) return;

    setState(() {
      _isLoadingDescription = true;
    });

    try {
      final placesService = PlacesService(dotenv.get('GOOGLE_MAPS_API_KEY'));
      final details = await placesService.getPlaceDetails(widget.attraction.placeId!);

      setState(() {
        _detailedDescription = details['description'] ??
            details['editorial_summary']?['overview'] ??
            widget.attraction.description;
      });
    } catch (e) {
      // Fall back to basic description if detailed fetch fails
      setState(() {
        _detailedDescription = widget.attraction.description;
      });
    } finally {
      setState(() {
        _isLoadingDescription = false;
      });
    }
  }

  Future<void> _initializeLocation() async {
    _currentLocation = await widget.currentLocation;
    _updateMapMarkers();
  }

  void _updateMapMarkers() {
    setState(() {
      _markers.clear();
      _polylines.clear();

      if (_currentLocation != null) {
        _markers.add(gmaps.Marker(
          markerId: const gmaps.MarkerId('currentLocation'),
          position: _currentLocation!,
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueBlue,
          ),
          infoWindow: const gmaps.InfoWindow(title: 'Your Location'),
        ));

        _markers.add(gmaps.Marker(
          markerId: gmaps.MarkerId(widget.attraction.id),
          position: gmaps.LatLng(
            widget.attraction.latitude,
            widget.attraction.longitude,
          ),
          infoWindow: gmaps.InfoWindow(title: widget.attraction.name),
        ));

        _polylines.add(gmaps.Polyline(
          polylineId: const gmaps.PolylineId('route'),
          color: Colors.blue,
          width: 5,
          points: [
            _currentLocation!,
            gmaps.LatLng(
              widget.attraction.latitude,
              widget.attraction.longitude,
            ),
          ],
        ));
      }
    });

    if (_currentLocation != null) {
      _mapController.animateCamera(
        gmaps.CameraUpdate.newLatLngBounds(
          gmaps.LatLngBounds(
            northeast: gmaps.LatLng(
              max(_currentLocation!.latitude, widget.attraction.latitude),
              max(_currentLocation!.longitude, widget.attraction.longitude),
            ),
            southwest: gmaps.LatLng(
              min(_currentLocation!.latitude, widget.attraction.latitude),
              min(_currentLocation!.longitude, widget.attraction.longitude),
            ),
          ),
          50,
        ),
      );
    }
  }

  Future<void> _openMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
          '&origin=${_currentLocation?.latitude},${_currentLocation?.longitude}'
          '&destination=${widget.attraction.latitude},${widget.attraction.longitude}'
          '&travelmode=walking',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.attraction.name),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: gmaps.GoogleMap(
              initialCameraPosition: gmaps.CameraPosition(
                target: gmaps.LatLng(
                  widget.attraction.latitude,
                  widget.attraction.longitude,
                ),
                zoom: 14,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                _updateMapMarkers();
              },
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.attraction.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  if (widget.attraction.rating != null)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          widget.attraction.rating!.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'About this place',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _isLoadingDescription
                      ? const CircularProgressIndicator()
                      : Text(
                    _detailedDescription ?? 'No description available',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openMaps,
                      icon: const Icon(Icons.directions),
                      label: const Text('Get Directions'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double max(double a, double b) => a > b ? a : b;
double min(double a, double b) => a < b ? a : b;