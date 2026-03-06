import 'latlng_model.dart';

class RouteModel {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final List<LatLngModel> points;
  final double distanceMeters;
  final int durationSeconds;
  final bool needsEnrichment;

  RouteModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.needsEnrichment = false,
  });

  RouteModel copyWith({
    String? name,
    double? distanceMeters,
    int? durationSeconds,
    bool? needsEnrichment,
  }) {
    return RouteModel(
      id: id,
      name: name ?? this.name,
      startTime: startTime,
      endTime: endTime,
      points: points,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      needsEnrichment: needsEnrichment ?? this.needsEnrichment,
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
        'needsEnrichment': needsEnrichment,
      };

  factory RouteModel.fromJson(Map json) {
    final pointsList = (json['points'] as List?) ?? [];
    return RouteModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? "Trip",
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : DateTime.now(),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : DateTime.now(),
      points: pointsList
          .map((e) => LatLngModel.fromJson(Map<String, dynamic>.from(e as Map? ?? {})))
          .toList(),
      distanceMeters: (json['distanceMeters'] ?? 0).toDouble(),
      durationSeconds: json['durationSeconds'] ?? 0,
      needsEnrichment: json['needsEnrichment'] ?? false,
    );
  }

  // -------------------------
  // UI FORMAT HELPERS
  // -------------------------

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return "${distanceMeters.toStringAsFixed(0)} m";
    }
    return "${(distanceMeters / 1000).toStringAsFixed(2)} km";
  }

  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;

    if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else if (minutes > 0) {
      return "${minutes}m";
    } else {
      return "${seconds}s";
    }
  }
}