import '../models/route_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RouteLocalDataSource {
  static const _key = 'routes';

  Future<List<RouteModel>> getAllRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null) return [];

    final decoded = jsonDecode(jsonString) as List;
    print("Loaded routes: ${decoded.length}");

    return decoded
        .map((e) => RouteModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveRoute(RouteModel route) async {
    final routes = await getAllRoutes();

    routes.removeWhere((r) => r.id == route.id);
    routes.add(route);

    await _saveAll(routes);
  }

  Future<void> deleteRoute(String routeId) async {
    final routes = await getAllRoutes();
    routes.removeWhere((r) => r.id == routeId);
    await _saveAll(routes);
    print("Routes after delete: ${routes.length}");
  }

  Future<void> _saveAll(List<RouteModel> routes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = routes.map((e) => e.toJson()).toList();
    await prefs.setString(_key, jsonEncode(encoded));
  }
}
