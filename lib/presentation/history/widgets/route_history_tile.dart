import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:routeledger/presentation/preview/route_preview_page.dart';
import '../../../data/models/route_model.dart';

class RouteHistoryTile extends StatelessWidget {
  final RouteModel route;

  const RouteHistoryTile({super.key, required this.route});

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final routeDay = DateTime(date.year, date.month, date.day);

    if (routeDay == today) return 'Today';
    if (routeDay == yesterday) return 'Yesterday';

    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dateLabel = _formatDateLabel(route.startTime);
    final startTime = DateFormat('hh:mm a').format(route.startTime);
    final endTime = DateFormat('hh:mm a').format(route.endTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: colorScheme.surface,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RoutePreviewPage(route: route)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ⭐ Route Name
                Text(
                  route.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                // ⭐ Date & Time
                Text(
                  "$dateLabel • $startTime - $endTime",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 18),

                // ⭐ Metrics Row
                Row(
                  children: [
                    _metricChip(
                      context,
                      icon: Icons.straighten,
                      value: route.formattedDistance,
                    ),
                    const SizedBox(width: 12),
                    _metricChip(
                      context,
                      icon: Icons.timer_outlined,
                      value: route.formattedDuration,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricChip(
    BuildContext context, {
    required IconData icon,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
