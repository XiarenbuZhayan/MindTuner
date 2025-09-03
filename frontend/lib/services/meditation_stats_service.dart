import 'package:shared_preferences/shared_preferences.dart';

class MeditationStatsService {
  static const String _todayStatsKey = 'meditation_stats_today';
  static const String _totalStatsKey = 'meditation_stats_total';
  static const String _lastSessionDateKey = 'meditation_last_session_date';

  /// 获取今日冥想时长（秒）
  static Future<int> getTodayMeditationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    final lastSessionDate = prefs.getString(_lastSessionDateKey);
    
    // 如果是新的一天，重置今日统计
    if (lastSessionDate != today) {
      await prefs.setString(_lastSessionDateKey, today);
      await prefs.setInt(_todayStatsKey, 0);
      return 0;
    }
    
    return prefs.getInt(_todayStatsKey) ?? 0;
  }

  /// 获取总冥想时长（秒）
  static Future<int> getTotalMeditationTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalStatsKey) ?? 0;
  }

  /// 添加冥想时长
  static Future<void> addMeditationTime(int seconds) async {
    print('📊 MeditationStatsService.addMeditationTime 开始执行...');
    print('  - 输入参数: $seconds 秒');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      print('  - SharedPreferences 实例获取成功');
      
      // 更新今日时长
      final todayTime = await getTodayMeditationTime();
      print('  - 当前今日时长: $todayTime 秒');
      final newTodayTime = todayTime + seconds;
      await prefs.setInt(_todayStatsKey, newTodayTime);
      print('  - 今日时长已更新: $newTodayTime 秒');
      
      // 更新总时长
      final totalTime = await getTotalMeditationTime();
      print('  - 当前总时长: $totalTime 秒');
      final newTotalTime = totalTime + seconds;
      await prefs.setInt(_totalStatsKey, newTotalTime);
      print('  - 总时长已更新: $newTotalTime 秒');
      
      // 更新最后会话日期
      final today = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString(_lastSessionDateKey, today);
      print('  - 最后会话日期已更新: $today');
      
      print('📊 冥想时长统计更新完成: +${seconds}秒, 今日: ${newTodayTime}秒, 总计: ${newTotalTime}秒');
    } catch (e) {
      print('❌ MeditationStatsService.addMeditationTime 执行失败: $e');
      rethrow;
    }
  }

  /// 格式化时长显示
  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  /// 获取今日统计信息
  static Future<Map<String, dynamic>> getTodayStats() async {
    print('📊 MeditationStatsService.getTodayStats 开始执行...');
    
    final todayTime = await getTodayMeditationTime();
    final totalTime = await getTotalMeditationTime();
    
    final result = {
      'todayTime': todayTime,
      'totalTime': totalTime,
      'todayFormatted': formatDuration(todayTime),
      'totalFormatted': formatDuration(totalTime),
    };
    
    print('📊 获取到统计数据:');
    print('  - 今日时长: $todayTime 秒 (${result['todayFormatted']})');
    print('  - 总时长: $totalTime 秒 (${result['totalFormatted']})');
    
    return result;
  }

  /// 重置所有统计
  static Future<void> resetAllStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_todayStatsKey);
    await prefs.remove(_totalStatsKey);
    await prefs.remove(_lastSessionDateKey);
    print('📊 冥想统计已重置');
  }

  /// 获取本周统计
  static Future<Map<String, int>> getWeeklyStats() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    Map<String, int> weeklyStats = {};
    
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateKey = date.toIso8601String().split('T')[0];
      final dayKey = 'meditation_stats_$dateKey';
      weeklyStats[dateKey] = prefs.getInt(dayKey) ?? 0;
    }
    
    return weeklyStats;
  }
}
