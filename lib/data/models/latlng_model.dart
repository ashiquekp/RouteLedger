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
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
    );
  }
}
