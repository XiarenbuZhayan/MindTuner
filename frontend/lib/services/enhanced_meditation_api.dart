import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class EnhancedMeditationApi {
  static String get baseUrl {
    // For real device testing, replace with your computer's LAN IP address
    // Example: 'http://192.168.1.100:8080'
    const String serverIP =
        '192.168.0.102'; // Please replace with your actual IP address

    if (Platform.isAndroid)
      return 'http://$serverIP:8080'; // Android real device
    if (Platform.isIOS) return 'http://$serverIP:8080'; // iOS real device
    return 'http://localhost:8080';
  }

  /// Generate enhanced meditation content based on user feedback
  static Future<Map<String, dynamic>> generateEnhancedMeditation({
    required String userId,
    required String mood,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enhanced-meditation/generate-enhanced-meditation'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'mood': mood,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to generate enhanced meditation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network request failed: $e');
    }
  }

  /// Get user feedback analysis results
  static Future<Map<String, dynamic>> getUserFeedbackAnalysis(
      String userId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/enhanced-meditation/user/$userId/feedback-analysis'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to get feedback analysis: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network request failed: $e');
    }
  }

  /// 获取用户反馈历史
  static Future<Map<String, dynamic>> getUserFeedbackHistory(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/enhanced-meditation/user/$userId/feedback-history?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('获取反馈历史失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }
}
