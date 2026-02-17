import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/services/route_export_service.dart';
import '../../data/models/route_model.dart';
import 'route_details_controller.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class RouteDetailsPage extends ConsumerStatefulWidget {
  final RouteModel route;

  const RouteDetailsPage({super.key, required this.route});

  @override
  ConsumerState<RouteDetailsPage> createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends ConsumerState<RouteDetailsPage> {
  GoogleMapController? _mapController;
  final _exportService = RouteExportService();

  late List<LatLng> _allPoints;
  final List<LatLng> _animatedPoints = [];

  Timer? _animationTimer;
  int _currentIndex = 0;
  LatLng? _movingMarker;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routeDetailsProvider.notifier).load(widget.route);
    });

    final rawPoints = widget.route.points
        .map((e) => LatLng(e.latitude, e.longitude))
        .toList();

    _allPoints = _interpolatePoints(rawPoints);
  }

  // ===============================
  // INTERPOLATION
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

  void _startReplayAnimation() {
    if (_allPoints.isEmpty) return;

    _animatedPoints.clear();
    _currentIndex = 0;

    _animationTimer?.cancel();

    _animationTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (_currentIndex >= _allPoints.length) {
        timer.cancel();

        Future.delayed(const Duration(milliseconds: 400), () async {
          _fitCamera();
          await Future.delayed(const Duration(milliseconds: 600));
          await _generateAndCacheThumbnail();
        });

        return;
      }

      final point = _allPoints[_currentIndex];

      setState(() {
        _animatedPoints.add(point);
        _movingMarker = point;
        _currentIndex++;
      });

      _mapController?.animateCamera(CameraUpdate.newLatLng(point));
    });
  }

  Set<Marker> _markers() {
    if (_allPoints.isEmpty) return {};

    final markers = <Marker>{
      Marker(markerId: const MarkerId("start"), position: _allPoints.first),
      Marker(markerId: const MarkerId("end"), position: _allPoints.last),
    };

    if (_movingMarker != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("moving"),
          position: _movingMarker!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    return markers;
  }

  Future<void> _generateAndCacheThumbnail() async {
    if (_mapController == null) return;

    try {
      final Uint8List? bytes = await _mapController!.takeSnapshot();

      if (bytes == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/route_${widget.route.id}.png");

      await file.writeAsBytes(bytes);
    } catch (e) {
      debugPrint("Snapshot error: $e");
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routeDetailsProvider);
    final route = state.route ?? widget.route;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showRenameDialog(route.name),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(route.name), Icon(Icons.edit_outlined)],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showExportOptions(route),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Hero(
              tag: "route_map_${route.id}",
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.45,
                child: GoogleMap(
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
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('dd-MM-yyyy').format(route.startTime)),
                  const SizedBox(height: 20),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.2,
                    children: [
                      _statCard("Distance", route.formattedDistance),
                      _statCard("Duration", route.formattedDuration),
                      _statCard(
                        "Avg Speed",
                        "${state.averageSpeedKmh.toStringAsFixed(1)} km/h",
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _startReplayAnimation,
                      child: const Text("Replay Route"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rename Route"),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(routeDetailsProvider.notifier)
                  .renameRoute(controller.text);

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportOptions(RouteModel route) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_snippet),
              title: const Text("Share as Text"),
              onTap: () async {
                Navigator.pop(context);
                await _exportService.shareAsText(route);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_present),
              title: const Text("Export as JSON"),
              onTap: () async {
                Navigator.pop(context);
                await _exportService.exportAsJson(route);
              },
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Export as GPX"),
              onTap: () async {
                Navigator.pop(context);
                await _exportService.exportAsGpx(route);
              },
            ),
          ],
        ),
      ),
    );
  }
}
