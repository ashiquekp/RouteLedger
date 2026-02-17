import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/route_model.dart';

class RouteExportService {
  Future<void> shareAsText(RouteModel route) async {
    final text =
        '''
${route.name}

Date: ${route.startTime}
Distance: ${route.formattedDistance}
Duration: ${route.formattedDuration}
Avg Speed: ${(route.distanceMeters / route.durationSeconds * 3.6).toStringAsFixed(1)} km/h
''';

    await Share.share(text);
  }

  Future<void> exportAsJson(RouteModel route) async {
    final directory = await getTemporaryDirectory();

    final file = File('${directory.path}/${route.name}.json');

    await file.writeAsString(jsonEncode(route.toJson()));

    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> exportAsGpx(RouteModel route) async {
    final directory = await getTemporaryDirectory();

    final safeName = route.name.replaceAll(" ", "_");
    final file = File('${directory.path}/$safeName.gpx');

    final gpxContent = _generateGpx(route);

    await file.writeAsString(gpxContent);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: "GPX export of ${route.name}");
  }

  String _generateGpx(RouteModel route) {
    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<gpx version="1.1" creator="YourAppName" xmlns="http://www.topografix.com/GPX/1/1">',
    );

    buffer.writeln('<metadata>');
    buffer.writeln('<name>${route.name}</name>');
    buffer.writeln('<time>${route.startTime.toUtc().toIso8601String()}</time>');
    buffer.writeln('</metadata>');

    buffer.writeln('<trk>');
    buffer.writeln('<name>${route.name}</name>');
    buffer.writeln('<trkseg>');

    for (final point in route.points) {
      buffer.writeln(
        '<trkpt lat="${point.latitude}" lon="${point.longitude}">',
      );
      buffer.writeln(
        '<time>${route.startTime.toUtc().toIso8601String()}</time>',
      );
      buffer.writeln('</trkpt>');
    }

    buffer.writeln('</trkseg>');
    buffer.writeln('</trk>');
    buffer.writeln('</gpx>');

    return buffer.toString();
  }
}
