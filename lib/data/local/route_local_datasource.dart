import 'package:hive/hive.dart';
import '../models/route_model.dart';

class RouteLocalDataSource {
  static const _boxName = 'routesBox';

  Box get _box => Hive.box(_boxName);

  Future<List<RouteModel>> getAllRoutes() async {
    final List<RouteModel> routes = [];
    
    for (var value in _box.values) {
      try {
        if (value is Map) {
          routes.add(RouteModel.fromJson(Map<String, dynamic>.from(value)));
        } else {
          print('Skipping non-map route value: ${value.runtimeType}');
        }
      } catch (e) {
        print('Error parsing route: $e');
        // We skip corrupted routes so the whole screen doesn't crash
      }
    }

    return routes;
  }

  Future<void> saveRoute(RouteModel route) async {
    await _box.put(route.id, route.toJson());
  }

  Future<void> updateRoute(RouteModel route) async {
    await _box.put(route.id, route.toJson());
  }

  Future<void> deleteRoute(String routeId) async {
    await _box.delete(routeId);
  }

  Future<List<RouteModel>> getRoutesNeedingEnrichment() async {
    return _box.values
        .map((e) => RouteModel.fromJson(Map<String, dynamic>.from(e)))
        .where((route) => route.needsEnrichment)
        .toList();
  }
}