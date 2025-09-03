import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../utils/constants.dart';
import '../services/reminder_service.dart';

class MeditationReminderScreen extends StatefulWidget {
  const MeditationReminderScreen({super.key});

  @override
  State<MeditationReminderScreen> createState() => _MeditationReminderScreenState();
}

class _MeditationReminderScreenState extends State<MeditationReminderScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isReminderEnabled = false;
  bool _isLoading = false;
  List<bool> _selectedDays = List.filled(7, false); // 周一到周日
  String? _errorMessage;

  final List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadReminderSettings();
    _checkNotificationPermissions();
  }

  Future<void> _checkNotificationPermissions() async {
    try {
      // 对于 Android，权限通常在初始化时自动请求
      // 对于 iOS，权限在 DarwinInitializationSettings 中设置
      print('🔔 通知权限检查完成');
      
      // 检查 Android 通知是否启用
      final bool? granted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      
      if (granted == true) {
        print('✅ 通知权限已授予');
      } else {
        print('⚠️ 通知权限可能被拒绝或未设置');
      }
    } catch (e) {
      print('❌ 检查通知权限失败: $e');
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      final bool? initialized = await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      if (initialized == true) {
        print('✅ 通知插件初始化成功');
      } else {
        print('❌ 通知插件初始化失败');
      }
    } catch (e) {
      print('❌ 通知初始化异常: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // 处理通知点击事件
    print('🔔 通知被点击: ${response.payload}');
    
    // 这里可以添加导航到冥想页面的逻辑
    // 例如：Navigator.pushNamed(context, '/meditation');
    
    // 暂时显示一个提示
    if (response.payload != null) {
      print('📱 通知载荷: ${response.payload}');
    }
  }

  Future<void> _loadReminderSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await ReminderService.loadReminderSettings();
      
      // 解析时间字符串
      final timeParts = (settings['time'] ?? '08:00').split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      setState(() {
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
        _isReminderEnabled = settings['isEnabled'] ?? false;
        _selectedDays = List<bool>.from(settings['days'] ?? [true, true, true, true, true, false, false]);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load reminder settings: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveReminderSettings() async {
    try {
      if (!_isReminderEnabled) {
        print('🔕 关闭提醒功能');
        await _cancelAllNotifications();
        await ReminderService.saveReminderSettings(
          isEnabled: false,
          time: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          days: _selectedDays,
        );
        _showSuccessMessage('Reminder disabled');
        
        // 返回结果，通知主页面更新状态
        if (mounted) {
          Navigator.pop(context, true);
        }
        return;
      }

      if (!_selectedDays.contains(true)) {
        _showErrorMessage('Please select at least one day');
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('💾 保存提醒设置...');
      
      // 保存设置到本地存储
      await ReminderService.saveReminderSettings(
        isEnabled: true,
        time: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        days: _selectedDays,
      );
      
      print('📅 设置通知...');
      // 设置通知
      await _scheduleNotifications();
      
      _showSuccessMessage('Reminder settings saved');
      print('✅ 提醒设置保存成功');
      
      // 返回结果，通知主页面更新状态
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ 保存提醒设置失败: $e');
      setState(() {
        _errorMessage = 'Failed to save reminder settings: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scheduleNotifications() async {
    try {
      print('🔔 开始设置通知...');
      
      // 取消所有现有通知
      await _cancelAllNotifications();
      print('🗑️ 已取消所有现有通知');

      // 为选中的每一天设置通知
      int scheduledCount = 0;
      for (int i = 0; i < 7; i++) {
        if (_selectedDays[i]) {
          await _scheduleNotificationForDay(i);
          scheduledCount++;
        }
      }
      
      print('✅ 成功设置了 $scheduledCount 个通知');
    } catch (e) {
      print('❌ 设置通知失败: $e');
      throw e;
    }
  }

  Future<void> _scheduleNotificationForDay(int dayOfWeek) async {
    try {
      final scheduledDate = _getNextScheduledDate(dayOfWeek);
      
      if (scheduledDate == null) {
        print('❌ 无法为星期${dayOfWeek + 1}设置通知：日期为空');
        return;
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'meditation_reminder',
        'Meditation Reminder',
        channelDescription: 'Daily meditation reminder notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2694EE), // 使用应用主题色
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      final tz.TZDateTime scheduledTZDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
      
      print('📅 设置通知: 星期${dayOfWeek + 1}, 时间: ${scheduledTZDateTime.toString()}');

      await flutterLocalNotificationsPlugin.zonedSchedule(
        dayOfWeek, // 使用星期几作为通知ID
        'Time for meditation!',
        'It\'s your meditation time. Let\'s begin your inner journey today.',
        scheduledTZDateTime,
        platformChannelSpecifics,
        payload: 'meditation_reminder_${dayOfWeek}', // 添加载荷
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      
      print('✅ 星期${dayOfWeek + 1}的通知设置成功');
    } catch (e) {
      print('❌ 设置星期${dayOfWeek + 1}通知失败: $e');
    }
  }

  DateTime? _getNextScheduledDate(int dayOfWeek) {
    try {
      final now = DateTime.now();
      final today = now.weekday - 1; // 转换为0-6的索引 (Monday=0, Sunday=6)
      
      int daysToAdd = dayOfWeek - today;
      if (daysToAdd <= 0) {
        daysToAdd += 7; // 如果今天已经过了，设置为下周
      }

      final scheduledDate = DateTime(
        now.year,
        now.month,
        now.day + daysToAdd,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // 如果设置的时间已经过了，设置为下周
      if (scheduledDate.isBefore(now)) {
        final nextWeekDate = scheduledDate.add(const Duration(days: 7));
        print('📅 时间已过，设置为下周: ${nextWeekDate.toString()}');
        return nextWeekDate;
      }

      print('📅 设置时间: ${scheduledDate.toString()}');
      return scheduledDate;
    } catch (e) {
      print('❌ 计算日期失败: $e');
      return null;
    }
  }

  Future<void> _cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      print('🗑️ 已取消所有通知');
    } catch (e) {
      print('❌ 取消通知失败: $e');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditation Reminder Settings'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 182, 210, 233),
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReminderToggle(),
                    const SizedBox(height: 24),
                    if (_isReminderEnabled) ...[
                      _buildTimeSelection(),
                      const SizedBox(height: 24),
                      _buildDaySelection(),
                      const SizedBox(height: 24),
                      _buildSaveButton(),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorMessage(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildReminderToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.notifications,
              color: _isReminderEnabled ? AppColors.primaryBlue : Colors.grey,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Meditation Reminder',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isReminderEnabled ? 'Reminder enabled' : 'Reminder disabled',
                    style: TextStyle(
                      color: _isReminderEnabled ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isReminderEnabled,
              onChanged: (value) {
                setState(() {
                  _isReminderEnabled = value;
                });
              },
              activeColor: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  'Reminder Time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedTime.format(context),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const Icon(Icons.edit, color: AppColors.primaryBlue),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  'Reminder Days',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                return FilterChip(
                  label: Text(_weekdays[index]),
                  selected: _selectedDays[index],
                  onSelected: (selected) {
                    setState(() {
                      _selectedDays[index] = selected;
                    });
                  },
                  selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                  checkmarkColor: AppColors.primaryBlue,
                  labelStyle: TextStyle(
                    color: _selectedDays[index] ? AppColors.primaryBlue : Colors.grey,
                    fontWeight: _selectedDays[index] ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveReminderSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Save Reminder Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
