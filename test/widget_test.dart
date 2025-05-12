import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sightseeker/main.dart';
import 'package:sightseeker/screens/home_screen.dart';

void main() {
  testWidgets('App loads and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SightSeekerApp());

    // Splash screen should show splash image
    expect(find.byType(Image), findsOneWidget);

    // Wait for splash duration + navigation
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify home screen appears
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
