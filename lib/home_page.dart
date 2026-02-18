import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:routeledger/core/background/location_task_handler.dart';
import 'package:routeledger/core/services/directions_service.dart';

import 'package:routeledger/core/services/route_storage_service.dart';
import 'package:routeledger/core/utils/route_namer.dart';
import 'package:routeledger/data/models/latlng_model.dart';
import 'package:routeledger/data/models/route_model.dart';
import 'package:routeledger/presentation/history/route_history_page.dart';
import 'package:routeledger/presentation/history/route_history_provider.dart';
import 'package:routeledger/presentation/summary/route_summary_page.dart';

class HomePage extends ConsumerStatefulWidget  {
  const HomePage({super.key});

  @override
 ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final DirectionsService _directionsService = DirectionsService(
    apiKey: dotenv.env['DIRECTIONS_API_KEY']!,
  );

  GoogleMapController? _mapController;
  bool _initializing = false;

  bool _isTracking = false;

  /// 🔹 Each inner list = one tracking session
  final List<List<LatLng>> _routeSegments = [];

  StreamSubscription<Position>? _positionStream;

  LatLng? _currentLatLng;

  // ===============================
  // 🔹 NEW: Route persistence helpers
  // ===============================
  final RouteStorageService _routeStorageService = RouteStorageService();
  DateTime? _currentRouteStartTime;

  Future<bool> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  Future<bool> _ensureGpsEnabled() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (enabled) return true;

    await Geolocator.openLocationSettings();
    return false;
  }

  Future<bool> _requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // ===============================
  // INITIAL LOCATION
  // ===============================
  @override
  void initState() {
    super.initState();
    _loadInitialLocation();
    _loadSavedRoutes(); // 🔹 NEW (history kept in memory)
  }

  Future<void> _loadInitialLocation() async {
    if (_initializing) return;
    _initializing = true;

    // 1️⃣ Location permission
    final granted = await _requestLocationPermission();
    if (!granted) {
      _initializing = false;
      return;
    }

    // 2️⃣ GPS enabled
    final gpsReady = await _ensureGpsEnabled();
    if (!gpsReady) {
      _initializing = false;
      return;
    }

    // 3️⃣ Now SAFE to access location
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentLatLng = LatLng(pos.latitude, pos.longitude);
    });

    _initializing = false;
  }

  // ===============================
  // 🔹 NEW: Load routes from storage
  // ===============================
  Future<void> _loadSavedRoutes() async {
    final routes = await _routeStorageService.loadAll();
    debugPrint('Loaded ${routes.length} saved routes');
  }

  // ===============================
  // START TRACKING
  // ===============================
  Future<void> startBackgroundTracking() async {
    if (_isTracking) return;

    await _requestNotificationPermission();

    setState(() {
      _isTracking = true;
      _currentRouteStartTime = DateTime.now(); // 🔹 NEW
      _routeSegments.add([]);
    });

    await FlutterForegroundTask.startService(
      notificationTitle: 'RouteLedger',
      notificationText: 'Tracking route…',
      callback: startCallback,
    );

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((position) {
          final point = LatLng(position.latitude, position.longitude);

          setState(() {
            _currentLatLng = point;
            _routeSegments.last.add(point);
          });

          _moveCamera(point);
        });
  }

  // ===============================
  // STOP TRACKING (SAVE ROUTE)
  // ===============================
  Future<void> stopBackgroundTracking() async {
    if (!_isTracking) return;

    await FlutterForegroundTask.stopService();
    await _positionStream?.cancel();

    final lastSegment = _routeSegments.isNotEmpty
        ? _routeSegments.last
        : <LatLng>[];

    double distanceMeters = 0;
    int durationSeconds = 0;

    // 🔥 Directions API call
    if (lastSegment.length >= 2) {
      final first = lastSegment.first;
      final last = lastSegment.last;

      final result = await _directionsService.getDistanceAndDuration(
        originLat: first.latitude,
        originLng: first.longitude,
        destLat: last.latitude,
        destLng: last.longitude,
      );

      if (result != null) {
        distanceMeters = result["distance"].toDouble();
        durationSeconds = result["duration"];
      }
    }

    // ⭐ Generate name AFTER distance is known
    final generatedName = RouteNamer.generateName(
      startTime: _currentRouteStartTime!,
      distanceMeters: distanceMeters,
    );

    if (lastSegment.length > 1 && _currentRouteStartTime != null) {
      final route = RouteModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: generatedName,
        startTime: _currentRouteStartTime!,
        endTime: DateTime.now(),
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        points: lastSegment
            .map(
              (e) => LatLngModel(latitude: e.latitude, longitude: e.longitude),
            )
            .toList(),
      );

      await _routeStorageService.save(route);
      ref.invalidate(routeHistoryProvider);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RouteSummaryPage(route: route)),
      );
    }

    setState(() {
      _isTracking = false;
      _currentRouteStartTime = null;
    });
  }

  // ===============================
  // POLYLINES BUILDER
  // ===============================
  Set<Polyline> _buildPolylines() {
    final Set<Polyline> polylines = {};

    for (int i = 0; i < _routeSegments.length; i++) {
      final segment = _routeSegments[i];

      if (segment.length < 2) continue;

      polylines.add(
        Polyline(
          polylineId: PolylineId('segment_$i'),
          points: segment,
          width: 5,
          color: Colors.blue,
        ),
      );
    }

    return polylines;
  }

  void _moveCamera(LatLng position) {
    if (_mapController == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 17, tilt: 45, bearing: 0),
      ),
    );
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    if (_currentLatLng == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('RouteLedger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RouteHistoryPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentLatLng!,
            zoom: 16,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          polylines: _buildPolylines(),
          onMapCreated: (controller) {
            _mapController = controller;
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _TrackingFAB(
        isTracking: _isTracking,
        onStart: startBackgroundTracking,
        onStop: stopBackgroundTracking,
      ),
    );
  }
}

class _TrackingFAB extends StatefulWidget {
  final bool isTracking;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _TrackingFAB({
    required this.isTracking,
    required this.onStart,
    required this.onStop,
  });

  @override
  State<_TrackingFAB> createState() => _TrackingFABState();
}

class _TrackingFABState extends State<_TrackingFAB>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.05,
    );

    _scale = Tween<double>(begin: 1, end: 0.95)
        .animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isTracking) {
      widget.onStop();
    } else {
      widget.onStart();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final backgroundColor = widget.isTracking
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) => _pressController.reverse(),
        onTapCancel: () => _pressController.reverse(),
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) {
            return Transform.scale(
              scale: _scale.value,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(40), // more pill-like
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    widget.isTracking
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    key: ValueKey(widget.isTracking),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    widget.isTracking
                        ? 'Stop Tracking'
                        : 'Start Tracking',
                    key: ValueKey(widget.isTracking),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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
