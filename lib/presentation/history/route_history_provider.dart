import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/route_storage_service.dart';
import '../../data/models/route_model.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

final routeHistoryProvider =
    AsyncNotifierProvider<RouteHistoryNotifier, List<RouteModel>>(
      RouteHistoryNotifier.new,
    );

class RouteHistoryNotifier extends AsyncNotifier<List<RouteModel>> {
  final RouteStorageService _storageService = RouteStorageService();

  @override
  Future<List<RouteModel>> build() async {
    return _loadRoutes();
  }

  Future<List<RouteModel>> _loadRoutes() async {
    final routes = await _storageService.loadAll();

    routes.sort((a, b) => b.startTime.compareTo(a.startTime));
    return routes;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadRoutes());
  }

  Future<void> delete(String id) async {
    await _storageService.delete(id);
    await _deleteThumbnail(id);
    await refresh();
  }

  Future<void> restore(RouteModel route) async {
    await _storageService.save(route);
    await refresh();
  }

  Future<void> _deleteThumbnail(String id) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/route_$id.png");

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // silent fail (not critical)
    }
  }
}
