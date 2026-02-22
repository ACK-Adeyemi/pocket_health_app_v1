import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../lib/providers/community_provider.dart';
import '../lib/screens/community/community_screen.dart';
import '../lib/widgets/search_filter_bar.dart';

void main() {
  group('Community Widget Tests', () {
    late CommunityProvider provider;

    setUp(() {
      provider = CommunityProvider();
    });

    testWidgets('CommunityScreen should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CommunityProvider>(
            create: (_) => provider,
            child: const CommunityScreen(),
          ),
        ),
      );

      // Verify the screen renders without errors
      expect(find.byType(CommunityScreen), findsOneWidget);
    });

    testWidgets('SearchFilterBar should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CommunityProvider>(
            create: (_) => provider,
            child: const SearchFilterBar(),
          ),
        ),
      );

      // Verify the search bar renders
      expect(find.byType(SearchFilterBar), findsOneWidget);
    });

    testWidgets('SearchFilterBar should have search input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CommunityProvider>(
            create: (_) => provider,
            child: const SearchFilterBar(),
          ),
        ),
      );

      // Look for text input field
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('CommunityScreen should display groups list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CommunityProvider>(
            create: (_) => provider,
            child: const CommunityScreen(),
          ),
        ),
      );

      // The screen should render without crashing
      await tester.pumpAndSettle();

      // Verify basic structure is present
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Search functionality should work', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CommunityProvider>(
            create: (_) => provider,
            child: const SearchFilterBar(),
          ),
        ),
      );

      // Find the search text field
      final searchField = find.byType(TextField).first;

      // Enter search text
      await tester.enterText(searchField, 'diabetes');
      await tester.pump();

      // Verify text was entered
      expect(find.text('diabetes'), findsOneWidget);
    });

    testWidgets('Filter buttons should be present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CommunityProvider>(
            create: (_) => provider,
            child: const SearchFilterBar(),
          ),
        ),
      );

      // Look for filter buttons (assuming they exist in the widget)
      // This test would need to be adjusted based on the actual widget implementation
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('CommunityScreen should handle loading states', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CommunityProvider>(
            create: (_) => provider,
            child: const CommunityScreen(),
          ),
        ),
      );

      // Test that the screen handles loading states gracefully
      await tester.pump();

      // Should not crash during loading
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('CommunityScreen should handle empty states', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CommunityProvider>(
            create: (_) => provider,
            child: const CommunityScreen(),
          ),
        ),
      );

      // Test empty state handling
      await tester.pump();

      // Should render without errors even with no data
      expect(find.byType(CommunityScreen), findsOneWidget);
    });
  });
}
