import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:routeledger/core/services/directions_service.dart';
import 'package:routeledger/core/services/location_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:routeledger/core/services/route_storage_service.dart';
import 'package:routeledger/core/utils/distance_utils.dart';
import 'package:routeledger/core/utils/route_namer.dart';
import 'package:routeledger/data/models/latlng_model.dart';
import 'package:routeledger/data/models/route_model.dart';
import 'package:routeledger/presentation/history/route_history_page.dart';
import 'package:routeledger/presentation/history/route_history_provider.dart';
import 'package:routeledger/presentation/summary/route_summary_page.dart';
import 'package:fl_location/fl_location.dart' as flloc;

enum LocationInitState {
  loading,
  permissionDenied,
  permissionPermanentlyDenied,
  gpsDisabled,
  ready,
  error,
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  final DirectionsService _directionsService = DirectionsService(
    apiKey: dotenv.env['DIRECTIONS_API_KEY']!,
  );

  LocationInitState _locationState = LocationInitState.loading;
  bool _isProcessingStart = false;

  GoogleMapController? _mapController;

  bool _isTracking = false;

  /// 🔹 Each inner list = one tracking session
  final List<List<LatLng>> _routeSegments = [];

  LatLng? _currentLatLng;

  // ===============================
  // 🔹 NEW: Route persistence helpers
  // ===============================
  final RouteStorageService _routeStorageService = RouteStorageService();
  DateTime? _currentRouteStartTime;

  // ===============================
  // INITIAL LOCATION
  // ===============================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLocationFlow();
    LocationService.instance.addLocationChangedCallback(_onLocationChanged);
    _checkActiveSession();
  }

  Future<void> _checkActiveSession() async {
    final box = await Hive.openBox('background_session_box');
    final activeStartTime = box.get('start_time');
    final dynamic data = box.get('points');

    if (activeStartTime != null &&
        await LocationService.instance.isRunningService) {
      if (mounted) {
        final List<LatLng> restoredPoints = [];
        if (data is List) {
          for (final item in data) {
            if (item is Map) {
              final lat = (item['lat'] ?? item['latitude'] ?? 0.0).toDouble();
              final lng = (item['lng'] ?? item['longitude'] ?? 0.0).toDouble();
              restoredPoints.add(LatLng(lat, lng));
            }
          }
        }

        setState(() {
          _isTracking = true;
          _currentRouteStartTime =
              DateTime.fromMillisecondsSinceEpoch(activeStartTime as int);
          _routeSegments.add(restoredPoints);

          if (restoredPoints.isNotEmpty) {
            _currentLatLng = restoredPoints.last;
          }
        });

        if (_currentLatLng != null) {
          _moveCamera(_currentLatLng!);
        }
      }
    }
    await box.close();
  }

  void _onLocationChanged(flloc.Location location) {
    if (!mounted) return;
    final point = LatLng(location.latitude, location.longitude);
    setState(() {
      _currentLatLng = point;
      if (_isTracking && _routeSegments.isNotEmpty) {
        _routeSegments.last.add(point);
      }
    });
    _moveCamera(point);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocationService.instance.removeLocationChangedCallback(_onLocationChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_locationState == LocationInitState.gpsDisabled ||
          _locationState == LocationInitState.permissionPermanentlyDenied) {
        _initializeLocationFlow();
      }
    }
  }

  Future<void> _initializeLocationFlow() async {
    setState(() {
      _locationState = LocationInitState.loading;
    });

    try {
      // ----------------------------
      // 1️⃣ Check Permission Status
      // ----------------------------
      PermissionStatus permissionStatus =
          await Permission.locationWhenInUse.status;

      if (permissionStatus.isDenied) {
        permissionStatus = await Permission.locationWhenInUse.request();
      }

      if (permissionStatus.isPermanentlyDenied) {
        setState(() {
          _locationState = LocationInitState.permissionPermanentlyDenied;
        });
        return;
      }

      if (!permissionStatus.isGranted) {
        setState(() {
          _locationState = LocationInitState.permissionDenied;
        });
        return;
      }

      // ----------------------------
      // 2️⃣ Check GPS / Location Service
      // ----------------------------
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          _locationState = LocationInitState.gpsDisabled;
        });
        return;
      }

      // ----------------------------
      // 3️⃣ Fetch Current Position
      // ----------------------------
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLatLng = LatLng(position.latitude, position.longitude);
        _locationState = LocationInitState.ready;
      });
    } catch (e) {
      setState(() {
        _locationState = LocationInitState.error;
      });
    }
  }

  // ===============================
  // START TRACKING
  // ===============================
  Future<void> startBackgroundTracking() async {
    if (_isTracking || _isProcessingStart) return;

    setState(() {
      _isProcessingStart = true;
    });

    try {
      // ----------------------------
      // 1️⃣ Location Permission
      // ----------------------------
      var permission = await Permission.locationWhenInUse.status;

      if (!permission.isGranted) {
        permission = await Permission.locationWhenInUse.request();

        if (!permission.isGranted) {
          if (permission.isPermanentlyDenied) {
            await openAppSettings();
          }
          return;
        }
      }

      // ----------------------------
      // 2️⃣ GPS Enabled
      // ----------------------------
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          _locationState = LocationInitState.gpsDisabled;
        });
        return;
      }

      // ----------------------------
      // 3️⃣ Notification Permission (Android 13+)
      // ----------------------------
      if (Platform.isAndroid) {
        var notificationStatus = await Permission.notification.status;

        if (!notificationStatus.isGranted &&
            !notificationStatus.isPermanentlyDenied) {
          notificationStatus = await Permission.notification.request();
        }

        if (!notificationStatus.isGranted) {
          return;
        }
      }

      // ----------------------------
      // 4️⃣ Safe to Start Tracking
      // ----------------------------
      setState(() {
        _isTracking = true;
        _currentRouteStartTime = DateTime.now();
        _routeSegments.add([]);
      });

      await LocationService.instance.start();
    } catch (e) {
      debugPrint("Start tracking failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingStart = false;
        });
      }
    }
  }

  // ===============================
  // STOP TRACKING (SAVE ROUTE)
  // ===============================
  Future<void> stopBackgroundTracking() async {
    if (!_isTracking || _currentRouteStartTime == null) {
      return;
    }

    await LocationService.instance.stop();

    // Ensure we give the isolate a tiny moment to close the box
    await Future.delayed(const Duration(milliseconds: 300));

    final box = await Hive.openBox('background_session_box');

    // Retrieve ALL gathered points from the background isolate
    final dynamic data = box.get('points');
    
    List<dynamic> rawList = [];
    if (data is List) {
      rawList = data;
    }

    // Clear session entries
    await box.clear();
    await box.close();

    final List<LatLngModel> lastSegment = [];

    for (final item in rawList) {
      if (item is Map) {
        try {
          final map = Map<String, dynamic>.from(item);
          lastSegment.add(LatLngModel.fromJson(map));
        } catch (e) {
          debugPrint('[HomePage] Error parsing point: $e');
        }
      }
    }

    if (lastSegment.length < 2) {
      setState(() {
        _isTracking = false;
        _currentRouteStartTime = null;
      });
      return;
    }

    final points = lastSegment;

    final distanceMeters = DistanceUtils.calculateTotalDistance(points);

    final durationSeconds = DateTime.now()
        .difference(_currentRouteStartTime!)
        .inSeconds;

    final generatedName = RouteNamer.generateName(
      startTime: _currentRouteStartTime!,
      distanceMeters: distanceMeters,
    );

    final route = RouteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: generatedName,
      startTime: _currentRouteStartTime!,
      endTime: DateTime.now(),
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      points: points,
      needsEnrichment: true,
    );

    await _routeStorageService.save(route);
    ref.invalidate(routeHistoryProvider);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RouteSummaryPage(route: route)),
    );

    setState(() {
      _isTracking = false;
      _currentRouteStartTime = null;
    });

    _tryEnrichRoute(route);
  }

  Future<void> _tryEnrichRoute(RouteModel route) async {
    try {
      final first = route.points.first;
      final last = route.points.last;

      final result = await _directionsService.getDistanceAndDuration(
        originLat: first.latitude,
        originLng: first.longitude,
        destLat: last.latitude,
        destLng: last.longitude,
      );

      if (result == null) return;

      final enriched = route.copyWith(
        distanceMeters: result["distance"].toDouble(),
        durationSeconds: result["duration"],
        needsEnrichment: false,
      );

      await _routeStorageService.update(enriched);
      ref.invalidate(routeHistoryProvider);
    } catch (_) {}
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
    if (_locationState != LocationInitState.ready) {
      return Scaffold(body: Center(child: _buildLocationStateUI()));
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
        onStart: _isProcessingStart ? () {} : startBackgroundTracking,
        onStop: stopBackgroundTracking,
      ),
    );
  }

  Widget _buildLocationStateUI() {
    switch (_locationState) {
      case LocationInitState.loading:
        return const CircularProgressIndicator();

      case LocationInitState.permissionDenied:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Location permission is required to continue.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _initializeLocationFlow,
              child: const Text('Grant Permission'),
            ),
          ],
        );

      case LocationInitState.permissionPermanentlyDenied:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Location permission permanently denied.\nPlease enable it in Settings.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: openAppSettings,
              child: const Text('Open Settings'),
            ),
          ],
        );

      case LocationInitState.gpsDisabled:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Location services are disabled.\nPlease enable GPS.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
              },
              child: const Text('Enable GPS'),
            ),
          ],
        );

      case LocationInitState.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Something went wrong while fetching location.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _initializeLocationFlow,
              child: const Text('Retry'),
            ),
          ],
        );

      case LocationInitState.ready:
        return const SizedBox.shrink();
    }
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

    _scale = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
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

    const brandPrimary = Color(0xFF66558e);
    const brandError = Color(0xFFD32F2F);

    final backgroundColor = widget.isTracking ? brandError : brandPrimary;

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
            return Transform.scale(scale: _scale.value, child: child);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(40), // more pill-like
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.35),
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
                    widget.isTracking ? 'Stop Tracking' : 'Start Tracking',
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
