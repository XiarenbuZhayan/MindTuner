import 'dart:convert';
import 'package:http/http.dart' as http;

const _baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

class BackendService {
  Future<bool> ping() async {
    final res = await http.get(Uri.parse('$_baseUrl/ping'))
        .timeout(const Duration(seconds: 5));
    return res.statusCode == 200 &&
           jsonDecode(res.body)['msg'] == 'pong';
  }
}
