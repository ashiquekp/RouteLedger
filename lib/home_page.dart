import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initLocationStream();
  }

  Future<void> _initLocationStream() async {
    bool ready = await ensureLocationReady();
    if (!ready) return;

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentLatLng = LatLng(pos.latitude, pos.longitude);
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      final latLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLatLng = latLng;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(latLng),
      );
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RouteLedger')),
      body: _currentLatLng == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLatLng!,
                zoom: 16,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: {
                Marker(
                  markerId: const MarkerId('me'),
                  position: _currentLatLng!,
                ),
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Start Tracking'),
        icon: const Icon(Icons.play_arrow),
        onPressed: () async {
          bool ready = await ensureLocationReady();
          if (!ready) return;

          await startBackgroundTracking();
        },
      ),
    );
  }
}
