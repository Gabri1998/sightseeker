import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Duration duration;
  final String? nextRoute;

  const SplashScreen({
    super.key,
    this.duration = const Duration(seconds: 3),
    this.nextRoute = '/home',
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(widget.duration);
    if (mounted) {
      Navigator.pushReplacementNamed(context, widget.nextRoute!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Larger logo with animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                width: size.width * 0.5,
                height: size.width * 0.5,
                child: Image.asset(
                  'assets/images/splash.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),
              // App name with animation
              AnimatedOpacity(
                duration: const Duration(milliseconds: 800),
                opacity: 1.0,
                child: Text(
                  'SightSeeker',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Larger progress indicator with padding
              Container(
                padding: const EdgeInsets.all(20),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 5,
                ),
              ),
              // Subtle tagline
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  'Discover amazing places around you',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}