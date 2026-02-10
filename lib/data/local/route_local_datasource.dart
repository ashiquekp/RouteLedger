import 'package:hive/hive.dart';
import '../models/route_model.dart';

class RouteLocalDataSource {
  static const String boxName = 'routes_box';

  Future<void> saveRoute(RouteModel route) async {
    final box = await Hive.openBox(boxName);
    await box.put(route.id, route.toJson());
  }

  Future<List<RouteModel>> getAllRoutes() async {
    final box = await Hive.openBox(boxName);

    return box.values
        .map((e) => RouteModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
