import 'latlng_model.dart';

class RouteModel {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final List<LatLngModel> points;

  RouteModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'points': points.map((e) => e.toJson()).toList(),
      };

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      points: (json['points'] as List)
          .map((e) => LatLngModel.fromJson(e))
          .toList(),
    );
  }
}
