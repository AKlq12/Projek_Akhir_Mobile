import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final query = '''
[out:json][timeout:30];
(
  nwr["leisure"="fitness_centre"](around:5000,-6.2,106.8);
  nwr["sport"="fitness"](around:5000,-6.2,106.8);
);
out center;
''';

  final urls = [
    'https://overpass-api.de/api/interpreter',
    'https://lz4.overpass-api.de/api/interpreter',
    'https://z.overpass-api.de/api/interpreter',
  ];

  for (final url in urls) {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': query},
      );
      print('URL: \$url');
      print('Status: \${response.statusCode}');
      if (response.statusCode != 200) {
        print('Error body: \${response.body.substring(0, 100)}...');
      }
    } catch (e) {
      print('Exception: \$e');
    }
  }
}
