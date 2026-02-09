import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:routeledger/core/background/location_task_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? _mapController;
  bool _initializing = false;

  bool _isTracking = false;

  /// 🔹 Each inner list = one tracking session
  final List<List<LatLng>> _routeSegments = [];

  StreamSubscription<Position>? _positionStream;

  LatLng? _currentLatLng;

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
  // INITIAL LOCATION (already works)
  // ===============================
  @override
  void initState() {
    super.initState();
    _loadInitialLocation();
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
  // START TRACKING (NEW SEGMENT)
  // ===============================
  Future<void> startBackgroundTracking() async {
    if (_isTracking) return;

    await _requestNotificationPermission();

    setState(() {
      _isTracking = true;
      _routeSegments.add([]); // 🔥 NEW SEGMENT
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
  // STOP TRACKING
  // ===============================
  Future<void> stopBackgroundTracking() async {
    if (!_isTracking) return;

    await FlutterForegroundTask.stopService();
    await _positionStream?.cancel();

    setState(() {
      _isTracking = false;
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
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLatLng!,
          zoom: 16,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        polylines: _buildPolylines(),
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isTracking
            ? stopBackgroundTracking
            : startBackgroundTracking,
        label: Text(_isTracking ? 'Stop Tracking' : 'Start Tracking'),
        icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
      ),
    );
  }
}
