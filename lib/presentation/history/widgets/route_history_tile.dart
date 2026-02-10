import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:routeledger/presentation/preview/route_preview_page.dart';

import '../../../data/models/route_model.dart';

class RouteHistoryTile extends StatelessWidget {
  final RouteModel route;

  const RouteHistoryTile({
    super.key,
    required this.route,
  });

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
    final dateLabel = _formatDateLabel(route.startTime);
    final startTime = DateFormat('hh:mm a').format(route.startTime);
    final endTime = DateFormat('hh:mm a').format(route.endTime);

    return ListTile(
      leading: const Icon(Icons.route),
      title: Text(dateLabel),
      subtitle: Text('$startTime – $endTime'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoutePreviewPage(route: route),
          ),
        );
      }
    );
  }
}
