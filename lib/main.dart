import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/expense.dart';
import 'models/itinerary_item.dart';
import 'models/trip.dart';
import 'providers/connectivity_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/itinerary_provider.dart';
import 'providers/trip_provider.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Hive initialisation ──────────────────────────────────────────────────
  await Hive.initFlutter();

  // Register generated TypeAdapters (one per @HiveType class).
  Hive.registerAdapter(TripAdapter());         // typeId 0
  Hive.registerAdapter(ItineraryItemAdapter()); // typeId 1
  Hive.registerAdapter(ExpenseAdapter());       // typeId 2

  // Open boxes before the widget tree is built so providers can access them
  // synchronously via Hive.box<T>() throughout the app.
  await Future.wait([
    Hive.openBox<Trip>('trips'),
    Hive.openBox<ItineraryItem>('itinerary'),
    Hive.openBox<Expense>('expenses'),
  ]);

  runApp(const TravelPlannerApp());
}

class TravelPlannerApp extends StatelessWidget {
  const TravelPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => ConnectivityProvider(),
        ),
        // TripProvider is application-scoped — it lives for the full session.
        ChangeNotifierProvider<TripProvider>(
          create: (_) => TripProvider()..loadTrips(),
        ),

        // ItineraryProvider and ExpenseProvider are also application-scoped
        // because they hold the "currently loaded trip" state that multiple
        // screens may share (e.g. detail screen + expense tab).
        ChangeNotifierProvider<ItineraryProvider>(
          create: (_) => ItineraryProvider(),
        ),

        ChangeNotifierProvider<ExpenseProvider>(
          create: (_) => ExpenseProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Travel Planner',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: AppRouter.initialRoute,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}

// Screens are registered via AppRouter.onGenerateRoute — no home widget needed.
