import 'latlng_model.dart';

class RouteModel {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final List<LatLngModel> points;
  final double distanceMeters;
  final int durationSeconds;

  RouteModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.points,
    this.distanceMeters = 0,
    this.durationSeconds = 0,
  });

  RouteModel copyWith({
    String? name,
  }) {
    return RouteModel(
      id: id,
      name: name ?? this.name,
      startTime: startTime,
      endTime: endTime,
      points: points,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'points': points.map((e) => e.toJson()).toList(),
        'distanceMeters': distanceMeters,
        'durationSeconds': durationSeconds,
      };

  factory RouteModel.fromJson(Map json) {
    return RouteModel(
      id: json['id'],
      name: json['name'] ?? "Trip",
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      points: (json['points'] as List)
          .map((e) => LatLngModel.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      distanceMeters: (json['distanceMeters'] ?? 0).toDouble(),
      durationSeconds: json['durationSeconds'] ?? 0,
    );
  }

  String get formattedDistance =>
      "${(distanceMeters / 1000).toStringAsFixed(2)} km";

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    return "$minutes min";
  }
}
