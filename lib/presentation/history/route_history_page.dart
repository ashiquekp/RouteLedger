import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routeledger/main.dart';
import 'route_history_provider.dart';
import 'widgets/route_history_tile.dart';

class RouteHistoryPage extends ConsumerStatefulWidget {
  const RouteHistoryPage({super.key});

  @override
  ConsumerState<RouteHistoryPage> createState() => _RouteHistoryPageState();
}

class _RouteHistoryPageState extends ConsumerState<RouteHistoryPage>
    with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when another page above is popped
    ref.read(routeHistoryProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(routeHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Route History')),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Something went wrong')),
        data: (routes) {
          if (routes.isEmpty) {
            return const Center(
              child: Text(
                'No routes recorded yet',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: ListView.builder(
              key: ValueKey(routes.length),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];

                return _AnimatedListItem(
                  index: index,
                  child: Dismissible(
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
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Route'),
                          content: const Text(
                            'Are you sure you want to delete this route?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
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
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;

  const _AnimatedListItem({required this.child, required this.index});

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + (widget.index * 50)),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
