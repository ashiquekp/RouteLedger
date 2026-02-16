import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/route_model.dart';
import 'route_history_provider.dart';
import 'widgets/route_history_tile.dart';

class RouteHistoryPage extends ConsumerWidget {
  const RouteHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(routeHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Route History')),
      body: routesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            const Center(child: Text('Something went wrong')),
        data: (routes) {
          if (routes.isEmpty) {
            return const Center(
              child: Text(
                'No routes recorded yet',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];

              return Dismissible(
                key: ValueKey(route.id),
                direction: DismissDirection.endToStart,
                dismissThresholds: const {
                  DismissDirection.endToStart: 0.4
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(27),
                  ),
                  child:
                      const Icon(Icons.delete, color: Colors.white),
                ),

                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Route'),
                      content: const Text(
                          'Are you sure you want to delete this route?'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },

                onDismissed: (_) async {
                  final deletedRoute = route;

                  await ref
                      .read(routeHistoryProvider.notifier)
                      .delete(route.id);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Route deleted'),
                      action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () async {
                          await ref
                              .read(routeHistoryProvider.notifier)
                              .restore(deletedRoute);
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
