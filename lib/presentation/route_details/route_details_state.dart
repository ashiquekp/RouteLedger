import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/route_model.dart';

class RouteDetailsState {
  final RouteModel? route;
  final List<LatLng> points;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final double averageSpeedKmh;
  final LatLngBounds? bounds;

  RouteDetailsState({
    required this.route,
    required this.points,
    required this.markers,
    required this.polylines,
    required this.averageSpeedKmh,
    required this.bounds,
  });

  factory RouteDetailsState.initial() => RouteDetailsState(
        route: null,
        points: [],
        markers: {},
        polylines: {},
        averageSpeedKmh: 0,
        bounds: null,
      );

  RouteDetailsState copyWith({
    RouteModel? route,
    List<LatLng>? points,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    double? averageSpeedKmh,
    LatLngBounds? bounds,
  }) {
    return RouteDetailsState(
      route: route ?? this.route,
      points: points ?? this.points,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      averageSpeedKmh: averageSpeedKmh ?? this.averageSpeedKmh,
      bounds: bounds ?? this.bounds,
    );
  }
}
