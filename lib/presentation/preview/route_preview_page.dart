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

  @override
  Widget build(BuildContext context) {
    if (_points.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No route points")),
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
                polylineId: const PolylineId("preview_route"),
                width: 5,
                points: _points,
                color: Colors.blue,
              ),
            },
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // 📊 STATS PANEL (NEW)
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Distance",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(widget.route.formattedDistance),
                      ],
                    ),

                    Column(
                      mainAxisSize: MainAxisSize.min,
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
