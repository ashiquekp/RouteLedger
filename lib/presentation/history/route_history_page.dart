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
      appBar: AppBar(title: const Text('Route History')),
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

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];

              return Dismissible(
                key: ValueKey(route.id),
                direction: DismissDirection.endToStart,
                dismissThresholds: const {DismissDirection.endToStart: 0.4},
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(27),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),

                // 🔥 CONFIRM BEFORE DELETE
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      title: const Text(
                        'Delete Route',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      content: const Text(
                        'Are you sure you want to delete this route?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.errorContainer,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },

                onDismissed: (direction) async {
                  final deletedRoute = route;

                  await _storageService.delete(route.id);

                  setState(() {
                    _routesFuture = _loadRoutes();
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Route deleted'),
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () async {
                          await _storageService.save(deletedRoute);

                          setState(() {
                            _routesFuture = _loadRoutes();
                          });
                        },
                      ),
                    ),
                  );
                },

                child: RouteHistoryTile(route: route),
              );
            },
          );
        },
      ),
    );
  }
}
