import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/route_model.dart';

class RoutePreviewPage extends StatefulWidget {
  final RouteModel route;

  const RoutePreviewPage({
    super.key,
    required this.route,
  });

  @override
  State<RoutePreviewPage> createState() => _RoutePreviewPageState();
}

class _RoutePreviewPageState extends State<RoutePreviewPage> {
  GoogleMapController? _mapController;

  late final List<LatLng> _points;

  @override
  void initState() {
    super.initState();
    _points = widget.route.points
        .map((e) => LatLng(e.latitude, e.longitude))
        .toList();
  }

  void _fitCameraToRoute() {
    if (_mapController == null || _points.isEmpty) return;

    double minLat = _points.first.latitude;
    double maxLat = _points.first.latitude;
    double minLng = _points.first.longitude;
    double maxLng = _points.first.longitude;

    for (final p in _points) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Preview'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _points.first,
          zoom: 16,
        ),
        polylines: {
          Polyline(
            polylineId: const PolylineId('preview_route'),
            points: _points,
            width: 5,
            color: Colors.blue,
          ),
        },
        markers: {
          Marker(
            markerId: const MarkerId('start'),
            position: _points.first,
            infoWindow: const InfoWindow(title: 'Start'),
          ),
          Marker(
            markerId: const MarkerId('end'),
            position: _points.last,
            infoWindow: const InfoWindow(title: 'End'),
          ),
        },
        onMapCreated: (controller) {
          _mapController = controller;
          Future.delayed(const Duration(milliseconds: 300), _fitCameraToRoute);
        },
      ),
    );
  }
}
