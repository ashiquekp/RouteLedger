import 'dart:convert';
import 'package:http/http.dart' as http;

class DirectionsService {
  final String apiKey;

  DirectionsService({required this.apiKey});

  Future<Map<String, dynamic>?> getDistanceAndDuration({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final url =
        "https://maps.googleapis.com/maps/api/directions/json"
        "?origin=$originLat,$originLng"
        "&destination=$destLat,$destLng"
        "&key=$apiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);

    if (data["routes"].isEmpty) return null;

    final leg = data["routes"][0]["legs"][0];

    return {
      "distance": leg["distance"]["value"], // meters
      "duration": leg["duration"]["value"], // seconds
    };
  }
}
