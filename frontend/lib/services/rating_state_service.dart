import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'rating_service.dart';

/// 评分状态管理服务
class RatingStateService {
  static const String _ratingStateKey = 'rating_state';
  static const String _lastRatingKey = 'last_rating';
  static const String _ratedRecordsKey = 'rated_records'; // 新增：已评分记录列表
  
  /// 保存评分状态
  static Future<void> saveRatingState({
    required bool hasRated,
    RatingRecord? ratingRecord,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 保存是否已评分状态
    await prefs.setBool(_ratingStateKey, hasRated);
    
    // 保存最后一次评分记录
    if (ratingRecord != null) {
      final ratingJson = {
        'ratingId': ratingRecord.ratingId,
        'userId': ratingRecord.userId,
        'ratingType': ratingRecord.ratingType.toString().split('.').last,
        'score': ratingRecord.score,
        'comment': ratingRecord.comment,
        'createdAt': ratingRecord.createdAt.toIso8601String(),
        'updatedAt': ratingRecord.updatedAt.toIso8601String(),
      };
      await prefs.setString(_lastRatingKey, jsonEncode(ratingJson));
    }
  }

  /// 保存特定记录的评分状态
  static Future<void> saveRecordRatingState({
    required String recordId,
    required bool hasRated,
    RatingRecord? ratingRecord,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 获取已评分记录列表
    final ratedRecords = await getRatedRecords();
    
    if (hasRated) {
      // 添加到已评分记录列表
      if (!ratedRecords.contains(recordId)) {
        ratedRecords.add(recordId);
        await prefs.setStringList(_ratedRecordsKey, ratedRecords);
      }
      
      // 保存特定记录的评分详情
      if (ratingRecord != null) {
        final recordRatingKey = 'record_rating_$recordId';
        final ratingJson = {
          'ratingId': ratingRecord.ratingId,
          'userId': ratingRecord.userId,
          'ratingType': ratingRecord.ratingType.toString().split('.').last,
          'score': ratingRecord.score,
          'comment': ratingRecord.comment,
          'createdAt': ratingRecord.createdAt.toIso8601String(),
          'updatedAt': ratingRecord.updatedAt.toIso8601String(),
        };
        await prefs.setString(recordRatingKey, jsonEncode(ratingJson));
      }
    } else {
      // 从已评分记录列表中移除
      ratedRecords.remove(recordId);
      await prefs.setStringList(_ratedRecordsKey, ratedRecords);
      
      // 删除特定记录的评分详情
      final recordRatingKey = 'record_rating_$recordId';
      await prefs.remove(recordRatingKey);
    }
  }

  /// 检查特定记录是否已评分
  static Future<bool> isRecordRated(String recordId) async {
    final prefs = await SharedPreferences.getInstance();
    final ratedRecords = prefs.getStringList(_ratedRecordsKey) ?? [];
    return ratedRecords.contains(recordId);
  }

  /// 获取特定记录的评分
  static Future<RatingRecord?> getRecordRating(String recordId) async {
    final prefs = await SharedPreferences.getInstance();
    final recordRatingKey = 'record_rating_$recordId';
    final ratingJsonString = prefs.getString(recordRatingKey);
    
    if (ratingJsonString == null) return null;
    
    try {
      final ratingJson = jsonDecode(ratingJsonString) as Map<String, dynamic>;
      
      return RatingRecord(
        ratingId: ratingJson['ratingId'],
        userId: ratingJson['userId'],
        ratingType: _parseRatingType(ratingJson['ratingType']),
        score: ratingJson['score'],
        comment: ratingJson['comment'],
        createdAt: DateTime.parse(ratingJson['createdAt']),
        updatedAt: DateTime.parse(ratingJson['updatedAt']),
      );
    } catch (e) {
      print('解析记录评分失败: $e');
      return null;
    }
  }

  /// 获取所有已评分的记录ID列表
  static Future<List<String>> getRatedRecords() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_ratedRecordsKey) ?? [];
  }
  
  /// 获取评分状态
  static Future<bool> getRatingState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_ratingStateKey) ?? false;
  }
  
  /// 获取最后一次评分记录
  static Future<RatingRecord?> getLastRating() async {
    final prefs = await SharedPreferences.getInstance();
    final ratingJsonString = prefs.getString(_lastRatingKey);
    
    if (ratingJsonString == null) return null;
    
    try {
      final ratingJson = jsonDecode(ratingJsonString) as Map<String, dynamic>;
      
      return RatingRecord(
        ratingId: ratingJson['ratingId'],
        userId: ratingJson['userId'],
        ratingType: _parseRatingType(ratingJson['ratingType']),
        score: ratingJson['score'],
        comment: ratingJson['comment'],
        createdAt: DateTime.parse(ratingJson['createdAt']),
        updatedAt: DateTime.parse(ratingJson['updatedAt']),
      );
    } catch (e) {
      print('解析评分记录失败: $e');
      return null;
    }
  }
  
  /// 清除评分状态
  static Future<void> clearRatingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ratingStateKey);
    await prefs.remove(_lastRatingKey);
  }

  /// 清除特定记录的评分状态
  static Future<void> clearRecordRatingState(String recordId) async {
    final prefs = await SharedPreferences.getInstance();
    final ratedRecords = await getRatedRecords();
    ratedRecords.remove(recordId);
    await prefs.setStringList(_ratedRecordsKey, ratedRecords);
  }

  /// 清除所有记录的评分状态
  static Future<void> clearAllRecordRatingStates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ratedRecordsKey);
  }
  
  /// 解析评分类型
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
