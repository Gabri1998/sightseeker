import 'package:get_it/get_it.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'elevation_service.dart';
import 'geocoding_service.dart';
import 'places_service.dart';
import 'street_view_service.dart';
import 'time_zone_service.dart';
import 'location_service.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  // Register services
  getIt.registerSingleton<PlacesService>(
    PlacesService(dotenv.get('GOOGLE_MAPS_API_KEY')),
  );

  getIt.registerSingleton<GeocodingService>(
    GeocodingService(dotenv.get('GOOGLE_MAPS_API_KEY')),
  );

  getIt.registerSingleton<StreetViewService>(
    StreetViewService(dotenv.get('GOOGLE_MAPS_API_KEY')),
  );

  getIt.registerSingleton<TimeZoneService>(
    TimeZoneService(dotenv.get('GOOGLE_MAPS_API_KEY')),
  );

  getIt.registerSingleton<ElevationService>(
    ElevationService(dotenv.get('GOOGLE_MAPS_API_KEY')),
  );

  getIt.registerSingleton<LocationService>(
    LocationService(),
  );
}