import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const RouteLedgerApp());
}

class RouteLedgerApp extends StatelessWidget {
  const RouteLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _permissionGranted = false;

  static const CameraPosition initialPosition = CameraPosition(
    target: LatLng(12.9716, 77.5946),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      setState(() {
        _permissionGranted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionGranted) {
      return const Scaffold(
        body: Center(child: Text('Waiting for location permission...')),
      );
    }

    return const Scaffold(
      body: GoogleMap(
        initialCameraPosition: initialPosition,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
