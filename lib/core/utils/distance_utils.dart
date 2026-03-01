import 'dart:math';

import 'package:routeledger/data/models/latlng_model.dart';

class DistanceUtils {
  static double calculateTotalDistance(List<LatLngModel> points) {
    double total = 0;

    for (int i = 0; i < points.length - 1; i++) {
      total += _distanceBetween(points[i], points[i + 1]);
    }

    return total;
  }

  static double _distanceBetween(
    LatLngModel start,
    LatLngModel end,
  ) {
    const earthRadius = 6371000;

    final dLat = _degToRad(end.latitude - start.latitude);
    final dLng = _degToRad(end.longitude - start.longitude);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(start.latitude)) *
            cos(_degToRad(end.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degToRad(double deg) => deg * pi / 180;
}