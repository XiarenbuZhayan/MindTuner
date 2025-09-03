import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 用户冥想偏好设置
class MeditationPreferences {
  final int targetDuration; // 目标时长（分钟）
  final String preferredStyle; // 偏好风格
  final String preferredFocus; // 偏好关注点
  final double lengthAdjustment; // 长度调整系数 (0.5-2.0)
  
  MeditationPreferences({
    this.targetDuration = 10,
    this.preferredStyle = 'calm',
    this.preferredFocus = 'breathing',
    this.lengthAdjustment = 1.0,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'targetDuration': targetDuration,
      'preferredStyle': preferredStyle,
      'preferredFocus': preferredFocus,
      'lengthAdjustment': lengthAdjustment,
    };
  }
  
  factory MeditationPreferences.fromJson(Map<String, dynamic> json) {
    return MeditationPreferences(
      targetDuration: json['targetDuration'] ?? 10,
      preferredStyle: json['preferredStyle'] ?? 'calm',
      preferredFocus: json['preferredFocus'] ?? 'breathing',
      lengthAdjustment: json['lengthAdjustment']?.toDouble() ?? 1.0,
    );
  }
}

/// 评分记录
class RatingRecord {
  final String recordId;
  final int score;
  final String? comment;
  final DateTime createdAt;
  final String meditationScript;
  final int actualDuration; // 实际时长（分钟）
  
  RatingRecord({
    required this.recordId,
    required this.score,
    this.comment,
    required this.createdAt,
    required this.meditationScript,
    required this.actualDuration,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'score': score,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'meditationScript': meditationScript,
      'actualDuration': actualDuration,
    };
  }
  
  factory RatingRecord.fromJson(Map<String, dynamic> json) {
    return RatingRecord(
      recordId: json['recordId'],
      score: json['score'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
      meditationScript: json['meditationScript'],
      actualDuration: json['actualDuration'],
    );
  }
}

/// 评分反馈优化服务
/// 根据用户的评分历史自动调整冥想生成参数
class FeedbackOptimizationService {
  static const String _userPreferencesKey = 'user_meditation_preferences';
  static const String _ratingHistoryKey = 'rating_history';
  
  /// 保存评分记录
  static Future<void> saveRatingRecord(RatingRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getRatingHistory();
    
    // 添加新记录
    history.add(record);
    
    // 只保留最近50条记录
    if (history.length > 50) {
      history.removeRange(0, history.length - 50);
    }
    
    // 保存到本地存储
    final historyJson = history.map((r) => r.toJson()).toList();
    await prefs.setString(_ratingHistoryKey, jsonEncode(historyJson));
    
    // 根据新评分更新用户偏好
    await _updatePreferencesFromRating(record);
  }
  
  /// 获取评分历史
  static Future<List<RatingRecord>> getRatingHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJsonString = prefs.getString(_ratingHistoryKey);
    
    if (historyJsonString == null) return [];
    
    try {
      final historyJson = jsonDecode(historyJsonString) as List<dynamic>;
      return historyJson.map((json) => RatingRecord.fromJson(json)).toList();
    } catch (e) {
      print('解析评分历史失败: $e');
      return [];
    }
  }
  
  /// 获取用户偏好设置
  static Future<MeditationPreferences> getUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final preferencesJsonString = prefs.getString(_userPreferencesKey);
    
    if (preferencesJsonString == null) {
      return MeditationPreferences();
    }
    
    try {
      final preferencesJson = jsonDecode(preferencesJsonString) as Map<String, dynamic>;
      return MeditationPreferences.fromJson(preferencesJson);
    } catch (e) {
      print('解析用户偏好失败: $e');
      return MeditationPreferences();
    }
  }
  
  /// 保存用户偏好设置
  static Future<void> saveUserPreferences(MeditationPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPreferencesKey, jsonEncode(preferences.toJson()));
  }
  
  /// 根据评分更新用户偏好
  static Future<void> _updatePreferencesFromRating(RatingRecord record) async {
    final currentPreferences = await getUserPreferences();
    final history = await getRatingHistory();
    
    // 分析最近的评分趋势
    final recentRatings = history.take(10).toList();
    if (recentRatings.length < 3) return; // 需要至少3个评分才开始优化
    
    // 计算平均评分
    final averageScore = recentRatings.map((r) => r.score).reduce((a, b) => a + b) / recentRatings.length;
    
    // 分析时长偏好
    final highRatedSessions = recentRatings.where((r) => r.score >= 4).toList();
    if (highRatedSessions.isNotEmpty) {
      final preferredDuration = highRatedSessions.map((r) => r.actualDuration).reduce((a, b) => a + b) / highRatedSessions.length;
      
      // 调整目标时长
      final newTargetDuration = (preferredDuration * 0.7 + currentPreferences.targetDuration * 0.3).round();
      
      // 调整长度系数
      double newLengthAdjustment = currentPreferences.lengthAdjustment;
      if (record.score >= 4) {
        // 高分：保持当前长度或稍微增加
        newLengthAdjustment = (newLengthAdjustment * 0.9 + 1.0 * 0.1).clamp(0.5, 2.0);
      } else if (record.score <= 2) {
        // 低分：调整长度
        if (record.comment?.toLowerCase().contains('长') == true || 
            record.comment?.toLowerCase().contains('too long') == true) {
          // 用户觉得太长，减少长度
          newLengthAdjustment = (newLengthAdjustment * 0.8).clamp(0.5, 2.0);
        } else if (record.comment?.toLowerCase().contains('短') == true || 
                   record.comment?.toLowerCase().contains('too short') == true) {
          // 用户觉得太短，增加长度
          newLengthAdjustment = (newLengthAdjustment * 1.2).clamp(0.5, 2.0);
        }
      }
      
      // 更新偏好设置
      final updatedPreferences = MeditationPreferences(
        targetDuration: newTargetDuration,
        preferredStyle: currentPreferences.preferredStyle,
        preferredFocus: currentPreferences.preferredFocus,
        lengthAdjustment: newLengthAdjustment,
      );
      
      await saveUserPreferences(updatedPreferences);
    }
  }
  
  /// 获取优化后的冥想生成参数
  static Future<Map<String, dynamic>> getOptimizedParameters({
    required String mood,
    required String description,
  }) async {
    final preferences = await getUserPreferences();
    final history = await getRatingHistory();
    
    // 基础参数
    final baseParams = {
      'mood': mood,
      'description': description,
      'targetDuration': preferences.targetDuration,
      'lengthAdjustment': preferences.lengthAdjustment,
    };
    
    // 根据历史评分添加优化建议
    if (history.isNotEmpty) {
      final recentRatings = history.take(5).toList();
      if (recentRatings.isNotEmpty) {
        final averageScore = recentRatings.map((r) => r.score).reduce((a, b) => a + b) / recentRatings.length;
        
        // 如果平均评分较低，添加改进建议
        if (averageScore < 3.5) {
          baseParams['improvement_suggestions'] = _generateImprovementSuggestions(recentRatings);
        }
      }
      
      // 添加用户偏好的风格和关注点
      baseParams['preferredStyle'] = preferences.preferredStyle;
      baseParams['preferredFocus'] = preferences.preferredFocus;
    }
    
    return baseParams;
  }
  
  /// 生成改进建议
  static List<String> _generateImprovementSuggestions(List<RatingRecord> recentRatings) {
    final suggestions = <String>[];
    
    // 分析评论中的关键词
    final comments = recentRatings.where((r) => r.comment != null).map((r) => r.comment!.toLowerCase()).join(' ');
    
    if (comments.contains('长') || comments.contains('too long')) {
      suggestions.add('Shorten meditation duration');
    }
    if (comments.contains('短') || comments.contains('too short')) {
      suggestions.add('Increase meditation duration');
    }
    if (comments.contains('无聊') || comments.contains('boring')) {
      suggestions.add('增加互动性内容');
    }
    if (comments.contains('复杂') || comments.contains('complex')) {
      suggestions.add('简化指导语言');
    }
    if (comments.contains('快') || comments.contains('fast')) {
      suggestions.add('放慢节奏');
    }
    if (comments.contains('慢') || comments.contains('slow')) {
      suggestions.add('适当加快节奏');
    }
    
    return suggestions;
  }
  
  /// 获取评分统计信息
  static Future<Map<String, dynamic>> getRatingStatistics() async {
    final history = await getRatingHistory();
    
    if (history.isEmpty) {
      return {
        'totalRatings': 0,
        'averageScore': 0.0,
        'ratingDistribution': {},
        'recentTrend': 'stable',
      };
    }
    
    // 计算平均评分
    final averageScore = history.map((r) => r.score).reduce((a, b) => a + b) / history.length;
    
    // 评分分布
    final distribution = <String, dynamic>{};
    for (int i = 1; i <= 5; i++) {
      distribution[i.toString()] = history.where((r) => r.score == i).length;
    }
    
    // 最近趋势
    final recent = history.take(5).toList();
    final older = history.skip(5).take(5).toList();
    
    String trend = 'stable';
    if (recent.isNotEmpty && older.isNotEmpty) {
      final recentAvg = recent.map((r) => r.score).reduce((a, b) => a + b) / recent.length;
      final olderAvg = older.map((r) => r.score).reduce((a, b) => a + b) / older.length;
      
      if (recentAvg > olderAvg + 0.5) {
        trend = 'improving';
      } else if (recentAvg < olderAvg - 0.5) {
        trend = 'declining';
      }
    }
    
    return {
      'totalRatings': history.length,
      'averageScore': averageScore,
      'ratingDistribution': distribution,
      'recentTrend': trend,
    };
  }
  
  /// 清除所有数据
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userPreferencesKey);
    await prefs.remove(_ratingHistoryKey);
  }
}