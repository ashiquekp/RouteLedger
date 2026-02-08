import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'location_controller.dart';

class LocationControls extends ConsumerWidget {
  const LocationControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTracking = ref.watch(locationTrackingProvider);

    return FloatingActionButton.extended(
      onPressed: () {
        if (isTracking) {
          ref.read(locationTrackingProvider.notifier).stopTracking();
        } else {
          ref.read(locationTrackingProvider.notifier).startTracking();
        }
      },
      label: Text(isTracking ? 'Stop Tracking' : 'Start Tracking'),
      icon: Icon(isTracking ? Icons.stop : Icons.play_arrow),
    );
  }
}
