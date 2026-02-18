import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'route_history_provider.dart';
import 'widgets/route_history_tile.dart';

class RouteHistoryPage extends ConsumerStatefulWidget {
  const RouteHistoryPage({super.key});

  @override
  ConsumerState<RouteHistoryPage> createState() => _RouteHistoryPageState();
}

class _RouteHistoryPageState extends ConsumerState<RouteHistoryPage> {

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(routeHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Route History')),
      body: routesAsync.when(
        loading: () => const _RouteHistoryShimmer(),
        error: (e, _) => const Center(child: Text('Something went wrong')),
        data: (routes) {
          if (routes.isEmpty) {
            return const _RouteHistoryEmptyState();
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

class _RouteHistoryEmptyState extends StatefulWidget {
  const _RouteHistoryEmptyState();

  @override
  State<_RouteHistoryEmptyState> createState() =>
      _RouteHistoryEmptyStateState();
}

class _RouteHistoryEmptyStateState extends State<_RouteHistoryEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Soft Icon Container
                Container(
                  height: 110,
                  width: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withOpacity(0.08),
                  ),
                  child: Icon(
                    Icons.route_rounded,
                    size: 50,
                    color: colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 28),

                /// Headline
                Text(
                  'No routes yet',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                /// Supporting text
                Text(
                  'Start tracking your journeys and they will appear here.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 28),

                /// CTA Button
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Tracking'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteHistoryShimmer extends StatelessWidget {
  const _RouteHistoryShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: _DetailedShimmerCard(),
      ),
    );
  }
}

class _DetailedShimmerCard extends StatefulWidget {
  const _DetailedShimmerCard();

  @override
  State<_DetailedShimmerCard> createState() =>
      _DetailedShimmerCardState();
}

class _DetailedShimmerCardState
    extends State<_DetailedShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final baseColor = colorScheme.surfaceVariant;
    final highlightColor =
        colorScheme.surface.withOpacity(0.6);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 + 2 * _controller.value, 0),
              end: Alignment(1 + 2 * _controller.value, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.1, 0.3, 0.4],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Leading circular placeholder
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: baseColor,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width: 16),

            /// Text placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Title line
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// Subtitle line
                  Container(
                    height: 14,
                    width: MediaQuery.of(context).size.width * 0.6,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Bottom metadata row
                  Row(
                    children: [
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 12,
                        width: 60,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
