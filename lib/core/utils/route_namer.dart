import 'package:intl/intl.dart';

class RouteNamer {
  static String generateName({
    required DateTime startTime,
    required double distanceMeters,
  }) {
    final hour = startTime.hour;
    final distanceKm = distanceMeters / 1000;

    // 🌅 Morning
    if (hour >= 5 && hour < 11) {
      return distanceKm < 3 ? "Morning Walk" : "Morning Ride";
    }

    // ☀ Day
    if (hour >= 11 && hour < 17) {
      return "Day Trip";
    }

    // 🌇 Evening
    if (hour >= 17 && hour < 21) {
      return distanceKm < 3 ? "Evening Walk" : "Evening Ride";
    }

    // 🌙 Night
    if (hour >= 21 || hour < 5) {
      return "Night Trip";
    }

    // fallback
    final formattedDate = DateFormat("dd MMM yyyy").format(startTime);
    return "Trip - $formattedDate";
  }
}
