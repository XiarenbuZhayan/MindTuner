import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// 评分类型枚举
enum RatingType {
  meditation, // 冥想评分
  mood,       // 心情评分
  general     // 通用评分
}

/// 评分记录模型
class RatingRecord {
  final String ratingId;
  final String userId;
  final RatingType ratingType;
  final int score;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  RatingRecord({
    required this.ratingId,
    required this.userId,
    required this.ratingType,
    required this.score,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RatingRecord.fromJson(Map<String, dynamic> json) {
    return RatingRecord(
      ratingId: json['rating_id'],
      userId: json['user_id'],
      ratingType: _parseRatingType(json['rating_type']),
      score: json['score'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  get feedbackTags => null;

  Map<String, dynamic> toJson() {
    return {
      'rating_id': ratingId,
      'user_id': userId,
      'rating_type': ratingType.toString().split('.').last,
      'score': score,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static RatingType _parseRatingType(String type) {
    switch (type) {
      case 'meditation':
        return RatingType.meditation;
      case 'mood':
        return RatingType.mood;
      case 'general':
        return RatingType.general;
      default:
        return RatingType.general;
    }
  }
}

/// 评分统计模型
class RatingStatistics {
  final int totalRatings;
  final double averageScore;
  final Map<int, int> scoreDistribution;
  final List<RatingRecord> recentRatings;

  RatingStatistics({
    required this.totalRatings,
    required this.averageScore,
    required this.scoreDistribution,
    required this.recentRatings,
  });

  factory RatingStatistics.fromJson(Map<String, dynamic> json) {
    return RatingStatistics(
      totalRatings: json['total_ratings'],
      averageScore: json['average_score'].toDouble(),
      scoreDistribution: Map<int, int>.from(json['score_distribution']),
      recentRatings: (json['recent_ratings'] as List)
          .map((rating) => RatingRecord.fromJson(rating))
          .toList(),
    );
  }
}

/// 评分服务类
class RatingService {
  static String get baseUrl {
    // 真机测试时，需要替换为您的电脑局域网IP地址
    // 例如：'http://192.168.1.100:8080'
    const String serverIP = '192.168.0.111'; // 请替换为您的实际IP地址
    
    if (Platform.isAndroid) return 'http://$serverIP:8080'; // Android真机
    if (Platform.isIOS) return 'http://$serverIP:8080';     // iOS真机
    return 'http://localhost:8080';      
  }
  static const String apiPath = '/rating';

  /// 创建评分
  static Future<RatingRecord> createRating({
    required String userId,
    required RatingType ratingType,
    required int score,
    String? comment,
  }) async {
    try {
      final url = '$baseUrl$apiPath/';
      final requestBody = {
        'user_id': userId,
        'rating_type': ratingType.toString().split('.').last,
        'score': score,
        'comment': comment,
      };
      
      print('🌐 发送评分请求到: $url');
      print('📝 请求数据: $requestBody');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📡 响应状态码: ${response.statusCode}');
      print('📄 响应内容: ${response.body}');

      if (response.statusCode == 200) {
        return RatingRecord.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('服务器错误 ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ 网络请求异常: $e');
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('No route to host')) {
        throw Exception('无法连接到服务器，请检查网络连接或服务器是否启动');
      }
      throw Exception('网络错误: $e');
    }
  }

  /// 获取用户评分列表
  static Future<List<RatingRecord>> getUserRatings({
    required String userId,
    RatingType? ratingType,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      
      if (ratingType != null) {
        queryParams['rating_type'] = ratingType.toString().split('.').last;
      }

      final uri = Uri.parse('$baseUrl$apiPath/user/$userId').replace(queryParameters: queryParams);
      
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> ratingsJson = jsonDecode(response.body);
        return ratingsJson.map((json) => RatingRecord.fromJson(json)).toList();
      } else {
        throw Exception('获取用户评分失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  /// 获取特定评分记录
  static Future<RatingRecord> getRating(String ratingId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$apiPath/$ratingId'));

      if (response.statusCode == 200) {
        return RatingRecord.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('获取评分记录失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  /// 更新评分记录
  static Future<RatingRecord> updateRating({
    required String ratingId,
    required int score,
    String? comment,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$apiPath/$ratingId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'score': score,
          'comment': comment,
        }),
      );

      if (response.statusCode == 200) {
        return RatingRecord.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('更新评分失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  /// 删除评分记录
  static Future<void> deleteRating(String ratingId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl$apiPath/$ratingId'));

      if (response.statusCode != 200) {
        throw Exception('删除评分失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  /// 获取用户评分统计
  static Future<RatingStatistics> getUserRatingStatistics({
    required String userId,
    RatingType? ratingType,
    int days = 30,
  }) async {
    try {
      final queryParams = <String, String>{
        'days': days.toString(),
      };
      
      if (ratingType != null) {
        queryParams['rating_type'] = ratingType.toString().split('.').last;
      }

      final uri = Uri.parse('$baseUrl$apiPath/user/$userId/statistics').replace(queryParameters: queryParams);
      
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return RatingStatistics.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('获取评分统计失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  /// 获取所有评分统计（管理员功能）
  static Future<RatingStatistics> getAllRatingStatistics({
    RatingType? ratingType,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (ratingType != null) {
        queryParams['rating_type'] = ratingType.toString().split('.').last;
      }

      final uri = Uri.parse('$baseUrl$apiPath/statistics/all').replace(queryParameters: queryParams);
      
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return RatingStatistics.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('获取所有评分统计失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  /// 批量创建评分
  static Future<List<RatingRecord>> createBatchRatings(List<Map<String, dynamic>> ratings) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiPath/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(ratings),
      );

      if (response.statusCode == 200) {
        final List<dynamic> ratingsJson = jsonDecode(response.body);
        return ratingsJson.map((json) => RatingRecord.fromJson(json)).toList();
      } else {
        throw Exception('批量创建评分失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  /// 健康检查
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      print('🏥 开始健康检查: $baseUrl$apiPath/health');
      final response = await http.get(Uri.parse('$baseUrl$apiPath/health'));

      print('🏥 健康检查响应: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('健康检查失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ 健康检查异常: $e');
      throw Exception('网络错误: $e');
    }
  }

  /// 测试后端连接
  static Future<bool> testConnection() async {
    try {
      await healthCheck();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取评分类型的中文名称
  static String getRatingTypeName(RatingType type) {
    switch (type) {
      case RatingType.meditation:
        return '冥想体验';
      case RatingType.mood:
        return '心情记录';
      case RatingType.general:
        return '通用评分';
    }
  }

  /// 获取评分等级描述
  static String getScoreDescription(int score) {
    switch (score) {
      case 1:
        return '很差';
      case 2:
        return '较差';
      case 3:
        return '一般';
      case 4:
        return '良好';
      case 5:
        return '优秀';
      default:
        return '未知';
    }
  }
}
