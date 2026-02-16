import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/local/route_local_datasource.dart';
import '../../../data/models/route_model.dart';
import '../history/route_history_provider.dart';
import 'route_details_state.dart';

final routeDetailsProvider =
    StateNotifierProvider.autoDispose<RouteDetailsController, RouteDetailsState>(
  (ref) => RouteDetailsController(ref),
);

class RouteDetailsController extends StateNotifier<RouteDetailsState> {
  RouteDetailsController(this.ref) : super(RouteDetailsState.initial());
  final Ref ref;
  final _datasource = RouteLocalDataSource();

  void load(RouteModel route) {
    final points = route.points
        .map((e) => LatLng(e.latitude, e.longitude))
        .toList();

    if (points.isEmpty) return;

    final markers = {
      Marker(
        markerId: const MarkerId('start'),
        position: points.first,
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: points.last,
      ),
    };

    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: points,
      width: 6,
    );

    final avgSpeed = route.durationSeconds == 0
        ? 0.0
        : ((route.distanceMeters / route.durationSeconds) * 3.6);

    final bounds = _calculateBounds(points);

    state = state.copyWith(
      route: route,
      points: points,
      markers: markers,
      polylines: {polyline},
      averageSpeedKmh: avgSpeed,
      bounds: bounds,
    );
  }

  Future<void> renameRoute(String newName) async {
    if (state.route == null) return;

    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final updatedRoute = state.route!.copyWith(name: trimmed);

    await _datasource.saveRoute(updatedRoute);

    state = state.copyWith(route: updatedRoute);

    ref.invalidate(routeHistoryProvider);
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
