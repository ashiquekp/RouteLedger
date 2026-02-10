import 'package:flutter/material.dart';

import '../../core/services/route_storage_service.dart';
import '../../data/models/route_model.dart';
import 'widgets/route_history_tile.dart';

class RouteHistoryPage extends StatefulWidget {
  const RouteHistoryPage({super.key});

  @override
  State<RouteHistoryPage> createState() => _RouteHistoryPageState();
}

class _RouteHistoryPageState extends State<RouteHistoryPage> {
  final RouteStorageService _storageService = RouteStorageService();

  late Future<List<RouteModel>> _routesFuture;

  @override
  void initState() {
    super.initState();
    _routesFuture = _loadRoutes();
  }

  Future<List<RouteModel>> _loadRoutes() async {
    final routes = await _storageService.loadAll();

    // Latest first
    routes.sort((a, b) => b.startTime.compareTo(a.startTime));
    return routes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route History'),
      ),
      body: FutureBuilder<List<RouteModel>>(
        future: _routesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No routes recorded yet',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final routes = snapshot.data!;

          return ListView.separated(
            itemCount: routes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final route = routes[index];
              return RouteHistoryTile(route: route);
            },
          );
        },
      ),
    );
  }
}
