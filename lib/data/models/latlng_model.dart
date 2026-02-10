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

  factory LatLngModel.fromJson(Map<String, dynamic> json) {
    return LatLngModel(
      latitude: json['lat'],
      longitude: json['lng'],
    );
  }
}
