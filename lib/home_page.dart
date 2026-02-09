import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'core/background/location_task_handler.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  bool _initializing = false;

  // ---------------- PERMISSION FLOW ----------------

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

  // ---------------- INITIAL SETUP ----------------

  Future<void> _initializeLocation() async {
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

  // ---------------- TRACKING ----------------

  Future<void> startTracking() async {
    // Ensure everything ready
    await _initializeLocation();

    if (_currentLatLng == null) return;

    // 4️⃣ Notification permission
    await _requestNotificationPermission();

    if (!await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.startService(
        notificationTitle: 'RouteLedger',
        notificationText: 'Tracking your route',
        callback: startCallback,
      );
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RouteLedger')),
      body: _currentLatLng == null
          ? Center(
              child: ElevatedButton(
                onPressed: _initializeLocation,
                child: const Text('Enable Location'),
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLatLng!,
                    zoom: 16,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: startTracking,
                    child: const Text('Start Tracking'),
                  ),
                ),
              ],
            ),
    );
  }
}
