import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:routeledger/presentation/route_details/route_details_page.dart';
import '../../../data/models/route_model.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class RouteHistoryTile extends StatefulWidget {
  final RouteModel route;

  const RouteHistoryTile({super.key, required this.route});

  @override
  State<RouteHistoryTile> createState() => _RouteHistoryTileState();
}

class _RouteHistoryTileState extends State<RouteHistoryTile> {
  bool _isPressed = false;

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final routeDay = DateTime(date.year, date.month, date.day);

    if (routeDay == today) return 'Today';
    if (routeDay == yesterday) return 'Yesterday';

    return DateFormat('dd MMM yyyy').format(date);
  }

  Future<File?> _getThumbnailFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/route_${widget.route.id}.png");

    if (await file.exists()) {
      return file;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dateLabel = _formatDateLabel(route.startTime);
    final startTime = DateFormat('hh:mm a').format(route.startTime);
    final endTime = DateFormat('hh:mm a').format(route.endTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _isPressed ? 0.97 : 1,
        child: Card(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RouteDetailsPage(route: route),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// =========================
                /// Thumbnail + Gradient + Badge
                /// =========================
                FutureBuilder<File?>(
                  future: _getThumbnailFile(),
                  builder: (context, snapshot) {
                    return Stack(
                      children: [
                        Hero(
                          tag: "route_map_${route.id}",
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 400),
                            opacity: snapshot.hasData ? 1 : 0.7,
                            child: snapshot.hasData
                                ? Image.file(
                                    snapshot.data!,
                                    height: 170,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 170,
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: Icon(Icons.map, size: 40),
                                    ),
                                  ),
                          ),
                        ),

                        /// Gradient overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),
                        ),

                        /// Distance + Duration badge
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.straighten,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  route.formattedDistance,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  route.formattedDuration,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                /// =========================
                /// Info Section
                /// =========================
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "$dateLabel • $startTime - $endTime",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
