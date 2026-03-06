class LatLngModel {
  final double latitude;
  final double longitude;

  LatLngModel({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lng': longitude,
      };

  factory LatLngModel.fromJson(Map json) {
    return LatLngModel(
      latitude: (json['lat'] ?? json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['lng'] ?? json['longitude'] ?? 0.0).toDouble(),
    );
  }
}
