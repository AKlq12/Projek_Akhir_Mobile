import 'dart:io';
import 'dart:convert';

void main() async {
  // Read .env file
  final envFile = File('.env');
  if (!await envFile.exists()) {
    print('.env file not found!');
    return;
  }
  
  final lines = await envFile.readAsLines();
  String apiKey = '';
  for (var line in lines) {
    if (line.startsWith('GEMINI_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }

  if (apiKey.isEmpty) {
    print('GEMINI_API_KEY not found in .env');
    return;
  }
  
  print('Found API Key: \${apiKey.substring(0, 10)}...');
  
  final httpClient = HttpClient();
  try {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=\$apiKey');
    final request = await httpClient.getUrl(url);
    final response = await request.close();
    
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      final models = data['models'] as List;
      print('\\nAvailable Models:');
      for (var m in models) {
        final name = m['name'];
        final supported = m['supportedGenerationMethods'] as List?;
        if (name.toString().contains('gemini')) {
           print('- \$name (Supports: \${supported?.join(', ')})');
        }
      }
    } else {
      print('API Error: \${response.statusCode}');
      print(responseBody);
    }
  } finally {
    httpClient.close();
  }
}
