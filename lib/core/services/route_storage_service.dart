import '../../data/local/route_local_datasource.dart';
import '../../data/models/route_model.dart';

class RouteStorageService {
  final _local = RouteLocalDataSource();

  Future<void> save(RouteModel route) {
    return _local.saveRoute(route);
  }

  Future<List<RouteModel>> loadAll() {
    return _local.getAllRoutes();
  }

  Future<void> delete(String routeId) {
    return _local.deleteRoute(routeId);
  }
}
