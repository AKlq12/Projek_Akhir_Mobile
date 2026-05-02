import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'AIzaSyAGqn46IxlLDT7JMSm48opUCtC78xNvngI';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=\$apiKey');
  
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    for (var model in data['models']) {
      print(model['name'].toString() + ' - ' + model['supportedGenerationMethods'].toString());
    }
  } else {
    print('Failed: ' + response.body);
  }
}
