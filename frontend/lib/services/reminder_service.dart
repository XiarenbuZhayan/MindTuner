import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReminderService {
  static const String _reminderKey = 'meditation_reminder_settings';
  static const String _isEnabledKey = 'reminder_enabled';
  static const String _timeKey = 'reminder_time';
  static const String _daysKey = 'reminder_days';

  // 提醒设置模型
  static Future<void> saveReminderSettings({
    required bool isEnabled,
    required String time, // 格式: "HH:mm"
    required List<bool> days, // 周一到周日
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool(_isEnabledKey, isEnabled);
    await prefs.setString(_timeKey, time);
    await prefs.setStringList(_daysKey, days.map((d) => d.toString()).toList());
    
    // 保存完整设置
    final settings = {
      'isEnabled': isEnabled,
      'time': time,
      'days': days,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_reminderKey, jsonEncode(settings));
  }

  static Future<Map<String, dynamic>> loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 尝试加载完整设置
    final settingsJson = prefs.getString(_reminderKey);
    if (settingsJson != null) {
      try {
        final settings = jsonDecode(settingsJson) as Map<String, dynamic>;
        return {
          'isEnabled': settings['isEnabled'] ?? false,
          'time': settings['time'] ?? '08:00',
          'days': List<bool>.from(settings['days'] ?? [true, true, true, true, true, false, false]),
          'lastUpdated': settings['lastUpdated'],
        };
      } catch (e) {
        print('Error parsing reminder settings: $e');
      }
    }
    
    // 如果完整设置不存在，尝试加载单独的值
    final isEnabled = prefs.getBool(_isEnabledKey) ?? false;
    final time = prefs.getString(_timeKey) ?? '08:00';
    final daysStrings = prefs.getStringList(_daysKey) ?? ['true', 'true', 'true', 'true', 'true', 'false', 'false'];
    final days = daysStrings.map((d) => d == 'true').toList();
    
    return {
      'isEnabled': isEnabled,
      'time': time,
      'days': days,
      'lastUpdated': null,
    };
  }

  static Future<bool> isReminderEnabled() async {
    final settings = await loadReminderSettings();
    return settings['isEnabled'] ?? false;
  }

  static Future<String> getReminderTime() async {
    final settings = await loadReminderSettings();
    return settings['time'] ?? '08:00';
  }

  static Future<List<bool>> getReminderDays() async {
    final settings = await loadReminderSettings();
    return List<bool>.from(settings['days'] ?? [true, true, true, true, true, false, false]);
  }

  static Future<void> clearReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reminderKey);
    await prefs.remove(_isEnabledKey);
    await prefs.remove(_timeKey);
    await prefs.remove(_daysKey);
  }

  // 检查今天是否需要提醒
  static Future<bool> shouldRemindToday() async {
    final settings = await loadReminderSettings();
    if (!(settings['isEnabled'] ?? false)) return false;
    
    final days = List<bool>.from(settings['days'] ?? []);
    final today = DateTime.now().weekday - 1; // 转换为0-6的索引
    
    return today < days.length && days[today];
  }

  // 获取下次提醒时间
  static Future<DateTime?> getNextReminderTime() async {
    final settings = await loadReminderSettings();
    if (!(settings['isEnabled'] ?? false)) return null;
    
    final time = settings['time'] ?? '08:00';
    final days = List<bool>.from(settings['days'] ?? []);
    
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    final now = DateTime.now();
    final today = now.weekday - 1;
    
    // 找到下一个选中的日期
    for (int i = 0; i < 7; i++) {
      final dayIndex = (today + i) % 7;
      if (days[dayIndex]) {
        final targetDate = DateTime(
          now.year,
          now.month,
          now.day + i,
          hour,
          minute,
        );
        
        // 如果今天的时间还没到，就返回今天的时间
        if (i == 0 && targetDate.isAfter(now)) {
          return targetDate;
        }
        
        // 否则返回下一个选中的日期
        if (i > 0) {
          return targetDate;
        }
      }
    }
    
    return null;
  }

  // 格式化时间显示
  static String formatTimeForDisplay(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  // 获取选中的日期描述
  static String getSelectedDaysDescription(List<bool> days) {
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final selectedDays = <String>[];
    
    for (int i = 0; i < days.length; i++) {
      if (days[i]) {
        selectedDays.add(weekdays[i]);
      }
    }
    
    if (selectedDays.isEmpty) return '未设置';
    if (selectedDays.length == 7) return '每天';
    if (selectedDays.length == 5 && 
        days[0] && days[1] && days[2] && days[3] && days[4]) {
      return '工作日';
    }
    if (selectedDays.length == 2 && days[5] && days[6]) {
      return '周末';
    }
    
    return selectedDays.join('、');
  }
}
