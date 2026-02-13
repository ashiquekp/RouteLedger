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

  // ===============================
  // FIT CAMERA TO ROUTE (IMPORTANT)
  // ===============================
  void _fitCamera() {
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
      CameraUpdate.newLatLngBounds(bounds, 60),
    );
  }

  // ===============================
  // START + END MARKERS
  // ===============================
  Set<Marker> _markers() {
    if (_points.isEmpty) return {};

    return {
      Marker(
        markerId: const MarkerId("start"),
        position: _points.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
        infoWindow: const InfoWindow(title: "Start"),
      ),
      Marker(
        markerId: const MarkerId("end"),
        position: _points.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
        infoWindow: const InfoWindow(title: "End"),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_points.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No route data")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Route Preview"),
      ),
      body: Stack(
        children: [

          // 🗺 MAP
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _points.first,
              zoom: 16,
            ),
            polylines: {
              Polyline(
                polylineId: const PolylineId("route"),
                points: _points,
                width: 6,
                color: Colors.blue,
              ),
            },
            markers: _markers(),
            onMapCreated: (controller) {
              _mapController = controller;

              // Delay slightly so map is ready
              Future.delayed(
                const Duration(milliseconds: 300),
                _fitCamera,
              );
            },
          ),

          // 📊 Distance + Duration panel
          Positioned(
            left: 12,
            right: 12,
            bottom: 20,
            child: Card(
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          "Distance",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(widget.route.formattedDistance),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          "Duration",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(widget.route.formattedDuration),
                      ],
                    ),
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
