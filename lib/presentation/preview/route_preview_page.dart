import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/route_model.dart';

class RoutePreviewPage extends StatefulWidget {
  final RouteModel route;

  const RoutePreviewPage({super.key, required this.route});

  @override
  State<RoutePreviewPage> createState() => _RoutePreviewPageState();
}

class _RoutePreviewPageState extends State<RoutePreviewPage> {
  GoogleMapController? _mapController;

  late List<LatLng> _allPoints;
  final List<LatLng> _animatedPoints = [];

  Timer? _animationTimer;
  int _currentIndex = 0;

  // 🚗 moving marker position
  LatLng? _movingMarker;

  @override
  void initState() {
    super.initState();

    final rawPoints = widget.route.points
        .map((e) => LatLng(e.latitude, e.longitude))
        .toList();

    _allPoints = _interpolatePoints(rawPoints);
  }

  // ===============================
  // INTERPOLATION (smooth animation)
  // ===============================
  List<LatLng> _interpolatePoints(List<LatLng> input) {
    if (input.length < 2) return input;

    final List<LatLng> result = [];

    for (int i = 0; i < input.length - 1; i++) {
      final start = input[i];
      final end = input[i + 1];

      result.add(start);

      const steps = 8;

      for (int j = 1; j < steps; j++) {
        final lat =
            start.latitude + (end.latitude - start.latitude) * (j / steps);

        final lng =
            start.longitude + (end.longitude - start.longitude) * (j / steps);

        result.add(LatLng(lat, lng));
      }
    }

    result.add(input.last);
    return result;
  }

  // ===============================
  // CAMERA FIT
  // ===============================
  void _fitCamera() {
    if (_mapController == null || _allPoints.isEmpty) return;

    double minLat = _allPoints.first.latitude;
    double maxLat = _allPoints.first.latitude;
    double minLng = _allPoints.first.longitude;
    double maxLng = _allPoints.first.longitude;

    for (final p in _allPoints) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  // ===============================
  // START REPLAY ANIMATION
  // ===============================
  void _startReplayAnimation() {
    if (_allPoints.isEmpty) return;

    _animatedPoints.clear();
    _currentIndex = 0;

    _animationTimer?.cancel();

    _animationTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (_currentIndex >= _allPoints.length) {
        timer.cancel();

        // ⭐ CENTER FULL ROUTE AFTER REPLAY
        Future.delayed(const Duration(milliseconds: 400), () async {
          _fitCamera();
        });

        return;
      }

      final point = _allPoints[_currentIndex];

      setState(() {
        _animatedPoints.add(point);
        _movingMarker = point;
        _currentIndex++;
      });

      // 🔥 smooth camera follow
      _mapController?.animateCamera(CameraUpdate.newLatLng(point));
    });
  }

  // ===============================
  // STATIC START/END MARKERS
  // ===============================
  Set<Marker> _markers() {
    if (_allPoints.isEmpty) return {};

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId("start"),
        position: _allPoints.first,
        infoWindow: const InfoWindow(title: "Start"),
      ),
      Marker(
        markerId: const MarkerId("end"),
        position: _allPoints.last,
        infoWindow: const InfoWindow(title: "End"),
      ),
    };

    // 🚗 moving marker
    if (_movingMarker != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("moving"),
          position: _movingMarker!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: "Replay"),
        ),
      );
    }

    return markers;
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_allPoints.isEmpty) {
      return const Scaffold(body: Center(child: Text("No route data")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Route Replay")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _allPoints.first,
              zoom: 16,
            ),
            polylines: {
              Polyline(
                polylineId: const PolylineId("animated_route"),
                points: _animatedPoints,
                width: 6,
                color: Colors.blue,
              ),
            },
            markers: _markers(),
            onMapCreated: (controller) {
              _mapController = controller;

              Future.delayed(const Duration(milliseconds: 300), () {
                _fitCamera();
                _startReplayAnimation();
              });
            },
          ),

          // Stats panel
          Positioned(
            left: 12,
            right: 12,
            bottom: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(widget.route.formattedDistance),
                    Text(widget.route.formattedDuration),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
