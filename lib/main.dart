import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:sightseeker/screens/home_screen.dart';
import 'package:sightseeker/screens/map_screen.dart';
import 'package:sightseeker/screens/splash_screen.dart';
import 'package:sightseeker/services/geocoding_service.dart';
import 'package:sightseeker/services/location_service.dart';
import 'package:sightseeker/services/places_service.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize error handling
  FlutterError.onError = (details) {
    debugPrint('Flutter error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  try {
    // Load environment variables
    await dotenv.load(fileName: '.env');
    print('API Key: ${dotenv.get('GOOGLE_MAPS_API_KEY')}');
    // Validate required environment variables
    final apiKey = dotenv.get('GOOGLE_MAPS_API_KEY');
    if (apiKey.isEmpty) {
      throw Exception('GOOGLE_MAPS_API_KEY not found in .env file');
    }

    // Set up dependency injection
    await setupDependencies(apiKey);

    // Start the app with error boundary
    runApp(
      const SightSeekerApp(),
    );
  } catch (e, stack) {
    // Comprehensive error handling
    debugPrint('Initialization error: $e');
    debugPrint('Stack trace: $stack');

    // Fallback UI
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                const SizedBox(height: 20),
                Text(
                  'App Initialization Failed',
                  style: ThemeData().textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> setupDependencies(String apiKey) async {
  final getIt = GetIt.instance;


  // Register navigator key
  getIt.registerSingleton<GlobalKey<NavigatorState>>(
    GlobalKey<NavigatorState>(),
  );

  // Register core services
  getIt.registerSingleton<LocationService>(
    LocationService(),
  );

  getIt.registerSingleton<PlacesService>(
    PlacesService(apiKey),
  );

  getIt.registerSingleton<GeocodingService>(
    GeocodingService(apiKey),
  );

  // Register other dependencies as needed
  // getIt.registerSingleton<OtherService>(OtherService());
}

class SightSeekerApp extends StatelessWidget {
  const SightSeekerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SightSeeker',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      initialRoute: '/',
      routes: _appRoutes(),
      onGenerateRoute: _onGenerateRoute,
      navigatorKey: GetIt.I<GlobalKey<NavigatorState>>(),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 2,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Map<String, WidgetBuilder> _appRoutes() {
    return {
      '/': (context) => const SplashScreen(),
      '/home': (context) => const HomeScreen(),
      '/map': (context) => const MapScreen(),
    };
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Text('Route ${settings.name} does not exist'),
        ),
      ),
    );
  }
}