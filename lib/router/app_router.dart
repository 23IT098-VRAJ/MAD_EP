import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../screens/expense/expense_add_screen.dart';
import '../screens/expense/expense_summary_screen.dart';
import '../screens/itinerary/itinerary_screen.dart';
import '../screens/search/search_filter_screen.dart';
import '../screens/trip/trip_create_screen.dart';
import '../screens/trip/trip_detail_screen.dart';
import '../screens/trip/trip_list_screen.dart';

// ── Route name constants ───────────────────────────────────────────────────────
// Use these everywhere instead of raw strings to prevent typos.

abstract class AppRoutes {
  static const String tripList    = '/';
  static const String tripCreate  = '/trip/create';
  static const String tripDetail  = '/trip/detail';
  static const String itinerary   = '/itinerary';
  static const String expenseAdd  = '/expense/add';
  static const String expenseSummary = '/expense/summary';
  static const String search      = '/search';
}

// ── Typed argument classes ────────────────────────────────────────────────────
// Each route that receives data uses one of these to keep things type-safe.

/// Arguments for [TripDetailScreen].
class TripDetailArgs {
  final Trip trip;
  const TripDetailArgs({required this.trip});
}

/// Arguments for [ItineraryScreen].
class ItineraryArgs {
  final String tripId;
  final String tripName; // used for AppBar title
  const ItineraryArgs({required this.tripId, required this.tripName});
}

/// Arguments for [ExpenseAddScreen].
class ExpenseAddArgs {
  final String tripId;
  final List<String> participants;
  const ExpenseAddArgs({required this.tripId, required this.participants});
}

/// Arguments for [ExpenseSummaryScreen].
class ExpenseSummaryArgs {
  final String tripId;
  final List<String> participants;
  const ExpenseSummaryArgs({required this.tripId, required this.participants});
}

// ── Router ────────────────────────────────────────────────────────────────────

class AppRouter {
  /// The initial route shown on cold start.
  static const String initialRoute = AppRoutes.tripList;

  /// Call this from [MaterialApp.onGenerateRoute].
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ── Trip ──────────────────────────────────────────────────────────────
      case AppRoutes.tripList:
        return _slide(const TripListScreen(), settings);

      case AppRoutes.tripCreate:
        return _slide(const TripCreateScreen(), settings);

      case AppRoutes.tripDetail:
        final args = settings.arguments as TripDetailArgs;
        return _slide(TripDetailScreen(trip: args.trip), settings);

      // ── Itinerary ─────────────────────────────────────────────────────────
      case AppRoutes.itinerary:
        final args = settings.arguments as ItineraryArgs;
        return _slide(
          ItineraryScreen(tripId: args.tripId, tripName: args.tripName),
          settings,
        );

      // ── Expense ───────────────────────────────────────────────────────────
      case AppRoutes.expenseAdd:
        final args = settings.arguments as ExpenseAddArgs;
        return _slide(
          ExpenseAddScreen(
            tripId: args.tripId,
            participants: args.participants,
          ),
          settings,
        );

      case AppRoutes.expenseSummary:
        final args = settings.arguments as ExpenseSummaryArgs;
        return _slide(
          ExpenseSummaryScreen(
            tripId: args.tripId,
            participants: args.participants,
          ),
          settings,
        );

      // ── Search ────────────────────────────────────────────────────────────
      case AppRoutes.search:
        return _slide(const SearchFilterScreen(), settings);

      // ── 404 fallback ──────────────────────────────────────────────────────
      default:
        return _slide(
          Scaffold(
            body: Center(
              child: Text('No route defined for "${settings.name}"'),
            ),
          ),
          settings,
        );
    }
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  static void goTripList(BuildContext context) =>
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.tripList, (_) => false);

  static void goTripCreate(BuildContext context) =>
      Navigator.pushNamed(context, AppRoutes.tripCreate);

  static void goTripDetail(BuildContext context, Trip trip) =>
      Navigator.pushNamed(
        context,
        AppRoutes.tripDetail,
        arguments: TripDetailArgs(trip: trip),
      );

  static void goItinerary(
          BuildContext context, String tripId, String tripName) =>
      Navigator.pushNamed(
        context,
        AppRoutes.itinerary,
        arguments: ItineraryArgs(tripId: tripId, tripName: tripName),
      );

  static void goExpenseAdd(
          BuildContext context, String tripId, List<String> participants) =>
      Navigator.pushNamed(
        context,
        AppRoutes.expenseAdd,
        arguments: ExpenseAddArgs(tripId: tripId, participants: participants),
      );

  static void goExpenseSummary(
          BuildContext context, String tripId, List<String> participants) =>
      Navigator.pushNamed(
        context,
        AppRoutes.expenseSummary,
        arguments:
            ExpenseSummaryArgs(tripId: tripId, participants: participants),
      );

  static void goSearch(BuildContext context) =>
      Navigator.pushNamed(context, AppRoutes.search);

  // ── Private builder ───────────────────────────────────────────────────────

  /// Wraps a widget in a right-to-left slide transition.
  static PageRouteBuilder<dynamic> _slide(
      Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.ease));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}
