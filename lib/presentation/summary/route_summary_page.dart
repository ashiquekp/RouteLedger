import 'package:flutter/material.dart';
import 'package:routeledger/presentation/route_details/route_details_page.dart';
import '../../data/models/route_model.dart';

class RouteSummaryPage extends StatelessWidget {
  final RouteModel route;

  const RouteSummaryPage({
    super.key,
    required this.route,
  });

  String get avgSpeed {
    if (route.durationSeconds == 0) return "0 km/h";

    final hours = route.durationSeconds / 3600;
    final km = route.distanceMeters / 1000;

    final speed = km / hours;

    return "${speed.toStringAsFixed(1)} km/h";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Completed"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 20),

            const Text(
              "🎉 Trip Completed",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [

                    _item("Distance", route.formattedDistance),
                    _item("Duration", route.formattedDuration),
                    _item("Avg Speed", avgSpeed),

                  ],
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text("View Route"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteDetailsPage(route: route),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                child: const Text("Close"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
