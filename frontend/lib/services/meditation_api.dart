import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'feedback_optimization_service.dart';

class GenerateResult {
  final String recordId;
  final String script;
  final String? audioUrl;
  GenerateResult({required this.recordId, required this.script, this.audioUrl});
}

class MeditationHistoryItem {
  final String recordId;
  final String mood;
  final String context;
  final String script;
  final DateTime createdAt;
  final bool isRegenerated;
  final int? score;
  final String? feedback;
  final String? audioUrl;

  MeditationHistoryItem({
    required this.recordId,
    required this.mood,
    required this.context,
    required this.script,
    required this.createdAt,
    required this.isRegenerated,
    this.score,
    this.feedback,
    this.audioUrl,
  });

  factory MeditationHistoryItem.fromJson(Map<String, dynamic> json) {
    return MeditationHistoryItem(
      recordId: json['record_id'] as String,
      mood: json['mood'] as String,
      context: json['context'] as String,
      script: json['script'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRegenerated: json['is_regenerated'] as bool,
      score: json['score'] as int?,
      feedback: json['feedback'] as String?,
      audioUrl: json['audio_url'] as String?,
    );
  }
}

class MeditationApi {
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

  // Test backend connection
  static Future<Map<String, dynamic>> testBackendConnection() async {
    final url = Uri.parse('$baseUrl/');
    try {
      print('🔍 测试后端连接: $url');
      final res = await http.get(url).timeout(const Duration(seconds: 10));

      return {
        'success': res.statusCode == 200,
        'statusCode': res.statusCode,
        'response': res.body,
        'url': url.toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'url': url.toString(),
      };
    }
  }

  // 生成冥想记录
  static Future<GenerateResult> generateMeditation({
    required String userId,
    required String mood,
    required String description,
  }) async {
    final url = Uri.parse('$baseUrl/meditation/generate-meditation');
    try {
      print('🎯 发送请求到: $url');
      print('📝 请求数据: userId=$userId, mood=$mood');

      // 获取优化后的参数
      final optimizedParams =
          await FeedbackOptimizationService.getOptimizedParameters(
        mood: mood,
        description: description,
      );

      print('🎯 优化参数: $optimizedParams');

      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'mood': mood,
              'description': description,
              'target_duration': optimizedParams['targetDuration'],
              'length_adjustment': optimizedParams['lengthAdjustment'],
              'preferred_style': optimizedParams['preferredStyle'],
              'preferred_focus': optimizedParams['preferredFocus'],
              if (optimizedParams.containsKey('improvement_suggestions'))
                'improvement_suggestions':
                    optimizedParams['improvement_suggestions'],
            }),
          )
          .timeout(const Duration(seconds: 60));

      print('📊 响应状态码: ${res.statusCode}');
      print('📄 响应内容: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return GenerateResult(
          recordId: data['record_id'] as String,
          script: data['meditation_script'] as String,
          audioUrl: data['audio_url'] as String?,
        );
      } else {
        throw Exception(
            'generate meditation failed: ${res.statusCode} ${res.body}');
      }
    } on TimeoutException {
      throw Exception(
          'request timeout, please check if the backend is reachable or try again later');
    } catch (e) {
      print('❌ 请求异常: $e');
      throw Exception('网络错误: $e');
    }
  }

  // 获取用户冥想历史记录
  static Future<List<MeditationHistoryItem>> getUserMeditationHistory({
    String? userId,
    int limit = 50,
  }) async {
    final targetUserId = userId ?? 'test-user';
    final url = Uri.parse('$baseUrl/history/$targetUserId?limit=$limit');
    try {
      print('📚 获取用户冥想历史记录: $url');

      final res = await http.get(url).timeout(const Duration(seconds: 30));

      print('📊 响应状态码: ${res.statusCode}');

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
        return data
            .map((json) => MeditationHistoryItem.fromJson(json))
            .toList();
      } else {
        throw Exception('获取历史记录失败: ${res.statusCode} ${res.body}');
      }
    } on TimeoutException {
      throw Exception('请求超时，请检查网络连接');
    } catch (e) {
      print('❌ 获取历史记录异常: $e');
      throw Exception('网络错误: $e');
    }
  }

  // 按日期分组获取用户冥想历史记录
  static Future<Map<String, List<MeditationHistoryItem>>>
      getUserMeditationHistoryGrouped({
    String? userId,
    int limit = 50,
  }) async {
    final targetUserId = userId ?? 'test-user';
    final url =
        Uri.parse('$baseUrl/history/$targetUserId/grouped?limit=$limit');
    try {
      print('📅 按日期分组获取用户冥想历史记录: $url');

      final res = await http.get(url).timeout(const Duration(seconds: 30));

      print('📊 响应状态码: ${res.statusCode}');

      if (res.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(res.body) as Map<String, dynamic>;
        final Map<String, List<MeditationHistoryItem>> groupedRecords = {};

        data.forEach((dateStr, recordsList) {
          final List<dynamic> records = recordsList as List<dynamic>;
          groupedRecords[dateStr] = records
              .map((json) => MeditationHistoryItem.fromJson(json))
              .toList();
        });

        return groupedRecords;
      } else {
        throw Exception('获取分组历史记录失败: ${res.statusCode} ${res.body}');
      }
    } on TimeoutException {
      throw Exception('请求超时，请检查网络连接');
    } catch (e) {
      print('❌ 获取分组历史记录异常: $e');
      throw Exception('网络错误: $e');
    }
  }

  // 获取单个冥想记录详情
  static Future<MeditationHistoryItem> getMeditationRecord({
    required String recordId,
  }) async {
    final url = Uri.parse('$baseUrl/history/record/$recordId');
    try {
      print('📖 获取冥想记录详情: $url');

      final res = await http.get(url).timeout(const Duration(seconds: 30));

      print('📊 响应状态码: ${res.statusCode}');

      if (res.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(res.body) as Map<String, dynamic>;
        return MeditationHistoryItem.fromJson(data);
      } else if (res.statusCode == 404) {
        throw Exception('记录不存在');
      } else {
        throw Exception('获取记录详情失败: ${res.statusCode} ${res.body}');
      }
    } on TimeoutException {
      throw Exception('请求超时，请检查网络连接');
    } catch (e) {
      print('❌ 获取记录详情异常: $e');
      throw Exception('网络错误: $e');
    }
  }

  // 更新冥想记录评价
  static Future<bool> updateMeditationFeedback({
    required String recordId,
    required int score,
    String? feedback,
  }) async {
    final url = Uri.parse('$baseUrl/history/record/$recordId/feedback');
    try {
      print('⭐ 更新冥想记录评价: $url');

      final Map<String, dynamic> body = {'score': score};
      if (feedback != null) {
        body['feedback'] = feedback;
      }

      final res = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      print('📊 响应状态码: ${res.statusCode}');

      if (res.statusCode == 200) {
        return true;
      } else {
        throw Exception('更新评价失败: ${res.statusCode} ${res.body}');
      }
    } on TimeoutException {
      throw Exception('请求超时，请检查网络连接');
    } catch (e) {
      print('❌ 更新评价异常: $e');
      throw Exception('网络错误: $e');
    }
  }

  // 删除冥想记录
  static Future<bool> deleteMeditationRecord({
    required String recordId,
  }) async {
    final url = Uri.parse('$baseUrl/history/record/$recordId');
    try {
      print('🗑️ 删除冥想记录: $url');

      final res = await http.delete(url).timeout(const Duration(seconds: 30));

      print('📊 响应状态码: ${res.statusCode}');

      if (res.statusCode == 200) {
        return true;
      } else {
        throw Exception('删除记录失败: ${res.statusCode} ${res.body}');
      }
    } on TimeoutException {
      throw Exception('请求超时，请检查网络连接');
    } catch (e) {
      print('❌ 删除记录异常: $e');
      throw Exception('网络错误: $e');
    }
  }
}
