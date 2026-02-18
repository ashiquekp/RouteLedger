import 'package:flutter/material.dart';
import 'package:routeledger/presentation/route_details/route_details_page.dart';
import '../../data/models/route_model.dart';

class RouteSummaryPage extends StatelessWidget {
  final RouteModel route;

  const RouteSummaryPage({super.key, required this.route});

  String get avgSpeed {
    if (route.durationSeconds == 0) return "0 km/h";

    final hours = route.durationSeconds / 3600;
    final km = route.distanceMeters / 1000;

    final speed = km / hours;

    return "${speed.toStringAsFixed(1)} km/h";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(""), // remove repetition
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            /// 🎉 Header
            Text(
              "🎉 Trip Completed",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Great ride! Here's your summary.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),

            const SizedBox(height: 32),

            /// 📊 Stats Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem("Distance", route.formattedDistance),
                  _divider(),
                  _statItem("Duration", route.formattedDuration),
                  _divider(),
                  _statItem("Avg Speed", avgSpeed),
                ],
              ),
            ),

            const Spacer(),

            /// Primary CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
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

            /// Secondary Action
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(height: 40, width: 1, color: Colors.grey.shade300);
  }
}
