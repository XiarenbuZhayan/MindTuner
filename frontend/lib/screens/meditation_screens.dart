import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart'; 
import '../utils/constants.dart'; 
import '../services/meditation_api.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_service.dart';
import '../services/meditation_stats_service.dart';

class MeditationGeneratePage extends StatefulWidget {
  const MeditationGeneratePage({super.key});

  @override
  State<MeditationGeneratePage> createState() => _MeditationGeneratePageState();
}

class _MeditationGeneratePageState extends State<MeditationGeneratePage> {

  // available for development
  final uid = FirebaseAuth.instance.currentUser?.uid ?? 'test-user'; 

  final _moodCtrl = TextEditingController(text: 'anxious');
  final _descCtrl = TextEditingController(text: 'I have a lot of work to do and I am not sure how to handle it');
  String? _script;
  String? _recordId;
  String? _audioUrl;
  bool _loading = false;
  String? _error;

  Future<void> _onGenerate() async {
    if (!mounted) return;
    
    setState(() { _loading = true; _error = null; _script = null; });

    try {
      final result = await MeditationApi.generateMeditation(
        userId: uid,
        mood: _moodCtrl.text,
        description: _descCtrl.text,
      );
      if (mounted) {
        setState(() { 
          _script = result.script; 
          _recordId = result.recordId;
          _audioUrl = result.audioUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = '$e'; });
      }
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  void _startMeditation() {
    if (_script != null && _recordId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MeditationPlayScreen(
            meditationScript: _script!,
            recordId: _recordId!,
            mood: _moodCtrl.text,
            audioUrl: _audioUrl,
            originalDescription: _descCtrl.text, // 传递原始描述
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('Meditation Generator')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _moodCtrl, decoration: const InputDecoration(labelText: 'Mood')),
            TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loading ? null : _onGenerate, child: const Text('Generate')),
            const SizedBox(height: 12),
            if (_loading) const CircularProgressIndicator(),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_script != null) ...[
              Expanded(child: SingleChildScrollView(child: Text(_script!))),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _startMeditation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start Meditation', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MeditationCompletedScreen extends StatelessWidget {
  final Duration meditationDuration;
  final String? startTime;

  const MeditationCompletedScreen({
    super.key,
    required this.meditationDuration,
    this.startTime,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = meditationDuration.inMinutes;
    final seconds = meditationDuration.inSeconds % 60;
    final formattedDuration = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(startTime ?? 'Meditation Complete'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Meditation Time',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              formattedDuration,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 32),
            const Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Well done!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Complete'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MeditationReviewScreen extends StatefulWidget {
  final String date;
  final String time;
  final String duration;
  final String type;
  final bool isFilled;

  const MeditationReviewScreen({
    super.key,
    required this.date,
    required this.time,
    required this.duration,
    required this.type,
    this.isFilled = false,
  });

  @override
  State<MeditationReviewScreen> createState() => _MeditationReviewScreenState();
}

class _MeditationReviewScreenState extends State<MeditationReviewScreen> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {//Set up audio listeners
    super.initState();
    if (widget.isFilled) {
      _rating = 3;
      _reviewController.text = 'Great! But the content is too long!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${widget.date} ${widget.time}'),
        actions: [
          Text(widget.duration),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.type,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                                      child: Text(
                  'Meditation content area\n\nThis is the meditation guide text...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
                         const Text(
               'Review',
               style: TextStyle(
                 fontSize: 18,
                 fontWeight: FontWeight.bold,
               ),
             ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      size: 32,
                      color: index < _rating ? Colors.yellow : Colors.grey,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _reviewController,
              maxLines: 3,
                             decoration: const InputDecoration(
                 hintText: 'Say something...',
                 border: OutlineInputBorder(),
                 labelText: 'Say something...',
               ),
            ),
            if (widget.isFilled) ...[
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Evaluation submitted', style: TextStyle(color: Colors.green)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
} 

class MeditationPlayScreen extends StatefulWidget {
  final String meditationScript;
  final String recordId;
  final String mood;
  final String? audioUrl;
  final String? originalDescription; // 添加原始描述参数

  const MeditationPlayScreen({
    super.key,
    required this.meditationScript,
    required this.recordId,
    required this.mood,
    this.audioUrl,
    this.originalDescription, // 可选参数
  });

  @override
  State<MeditationPlayScreen> createState() => _MeditationPlayScreenState();
}

class _MeditationPlayScreenState extends State<MeditationPlayScreen> {
  bool _isPlaying = false;                    // Current playback status (play/pause)
  Duration _position = Duration.zero;         // Current playback position
  Duration _duration = Duration.zero;         // Total audio duration
  DateTime? _startTime;                       // Meditation start time
  bool _isLooping = false;                    // Loop playback status
  double _volume = 1.0;                       // Volume (0.0-1.0)
  bool _shouldStopAudioOnPop = true;          // Control whether to stop audio when returning
  bool _isRegenerating = false;               // Regeneration status
  bool _hasRecordedTime = false;              // Whether duration has been recorded
  bool _isAudioPreloaded = false;             // Whether audio has been preloaded

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _setupAudioListeners();
    print('MeditationPlayScreen initState - audioUrl: ${widget.audioUrl}');
    
    // Preload audio information to get duration
    if (widget.audioUrl != null) {
      _preloadAudioInfo();
    }
  }

  void _setupAudioListeners() {
    _positionSubscription = AudioService.positionStream.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });

    _durationSubscription = AudioService.durationStream.listen((dur) {
      if (mounted) {
        setState(() => _duration = dur ?? Duration.zero);
        print('Audio duration: $dur');
      }
    });

    _stateSubscription = AudioService.stateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
        print('Audio state: ${state.processingState} - ${state.playing}');
        
        // 当音频播放完成时记录冥想时长并自动结束冥想
        if (state.processingState == ProcessingState.completed) {
          print('🎵 音频播放完成，自动结束冥想');
          _autoCompleteMeditation();
        }
      }
    });
  }

  // 预加载音频信息以获取时长
  Future<void> _preloadAudioInfo() async {
    if (widget.audioUrl == null) return;
    
    try {
      print('🎵 开始预加载音频信息...');
      print('  - 音频URL: ${widget.audioUrl}');
      
      // 使用AudioService预加载音频
      await AudioService.initialize();
      await AudioService.player.setUrl(widget.audioUrl!);
      
      if (mounted) {
        setState(() {
          _isAudioPreloaded = true;
        });
      }
      
      print('✅ 音频预加载完成');
    } catch (e) {
      print('❌ 音频预加载失败: $e');
    }
  }

  Future<void> _stopAudio() async {
    try {
      await AudioService.stop();
      print('Audio stopped');
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  @override
  void dispose() {
    _stopAudio();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    
    // 记录冥想时长（如果还没有记录过）
    _recordMeditationTime();
    
    // 如果还没有返回过，且已经记录了时长，则传递刷新信号
    if (_hasRecordedTime && mounted) {
      print('🔄 页面销毁时传递刷新信号');
      Navigator.pop(context, true);
    }
    
    super.dispose();
  }

  // 记录冥想时长
  void _recordMeditationTime() {
    print('🔍 开始记录冥想时长检查...');
    print('  - _hasRecordedTime: $_hasRecordedTime');
    print('  - _startTime: $_startTime');
    print('  - 当前时间: ${DateTime.now()}');
    
    // 避免重复记录
    if (_hasRecordedTime) {
      print('❌ 已经记录过时长，跳过');
      return;
    }
    
    if (_startTime == null) {
      print('❌ 没有开始时间，跳过');
      return;
    }
    
    final endTime = DateTime.now();
    final duration = endTime.difference(_startTime!);
    final seconds = duration.inSeconds;
    
    print('📊 冥想时长计算:');
    print('  - 开始时间: $_startTime');
    print('  - 结束时间: $endTime');
    print('  - 总时长: ${duration.inMinutes}分${duration.inSeconds % 60}秒 (${seconds}秒)');
    print('  - 秒数: $seconds');
    
    // 只记录超过30秒的冥想
    if (seconds >= 30) {
      print('✅ 冥想时长符合要求，开始记录统计...');
      print('  - 准备调用 MeditationStatsService.addMeditationTime($seconds)');
      
      MeditationStatsService.addMeditationTime(seconds).then((_) {
        print('✅ 冥想时长统计更新完成');
        print('  - 异步操作成功完成');
      }).catchError((error) {
        print('❌ 冥想时长统计更新失败: $error');
        print('  - 错误详情: $error');
      });
      
      _hasRecordedTime = true; // 标记已记录
      print('  - _hasRecordedTime 已设置为 true');
    } else {
      print('⚠️ 冥想时长过短 (${seconds}秒 < 30秒)，不记录统计');
      print('  - 需要至少30秒才能记录统计');
    }
  }

  void _togglePlayPause() async {
    if (widget.audioUrl == null) {
      print('No audio URL available');
      return;
    }

    try {
      if (_isPlaying) {
        print('Pausing audio');
        await AudioService.pause();
      } else {
        print('Playing audio from: ${widget.audioUrl}');
        // 如果音频已经预加载，直接播放；否则重新设置URL
        if (_isAudioPreloaded) {
          await AudioService.resume();
        } else {
          await AudioService.play(widget.audioUrl!);
        }
      }
    } catch (e) {
      print('Audio playback error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio playback failed: $e')),
        );
      }
    }
  }


  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
    });
    // TODO: Implement loop functionality in AudioService
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isLooping ? 'Loop playback enabled' : 'Loop playback disabled'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _rewind() async {
    try {
      final newPosition = _position - const Duration(seconds: 10);
      if (newPosition.inMilliseconds >= 0) {
        await AudioService.seek(newPosition);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rewind 10 seconds'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      print('Rewind error: $e');
              ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rewind failed: $e'), duration: const Duration(seconds: 2)),
        );
    }
  }

  void _fastForward() async {
    try {
      final newPosition = _position + const Duration(seconds: 10);
      if (newPosition.inMilliseconds <= _duration.inMilliseconds) {
        await AudioService.seek(newPosition);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fast forward 10 seconds'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      print('Fast forward error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fast forward failed: $e'), duration: const Duration(seconds: 2)),
      );
    }
  }

  void _stop() async {
    try {
      await AudioService.stop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio stopped'), duration: Duration(seconds: 1)),
      );
    } catch (e) {
      print('Stop error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stop failed: $e'), duration: const Duration(seconds: 2)),
      );
    }
  }

  void _showVolumeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Volume Control'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: _volume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '${(_volume * 100).round()}%',
              onChanged: (value) {
                setState(() {
                  _volume = value;
                });
                AudioService.setVolume(value);
              },
            ),
            Text('Volume: ${(_volume * 100).round()}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // 结束冥想
  void _endMeditation() async {
    print('🛑 用户主动结束冥想...');
    
    // 停止音频
    await _stopAudio();
    print('🔇 音频已停止');
    
    // 记录冥想时长
    _recordMeditationTime();
    print('📊 冥想时长记录完成');
    
    // 显示结束消息
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meditation ended, time recorded'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // 延迟后返回上一页并传递刷新信号
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          print('🔄 返回上一页并传递刷新信号');
          Navigator.pop(context, true); // 传递true表示需要刷新统计
        }
      });
    }
  }

  // 自动完成冥想（音频播放完成时调用）
  void _autoCompleteMeditation() async {
    print('🎵 自动完成冥想...');
    
    // 记录冥想时长
    _recordMeditationTime();
    print('📊 冥想时长记录完成');
    
    // 显示完成消息
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meditation completed, time recorded'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      // 延迟后返回上一页并传递刷新信号
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          print('🔄 自动返回上一页并传递刷新信号');
          Navigator.pop(context, true); // 传递true表示需要刷新统计
        }
      });
    }
  }

  // 测试冥想时长记录
  void _testMeditationTime() async {
    print('🧪 开始测试冥想时长记录...');
    
    // 模拟60秒的冥想时长
    const testSeconds = 60;
    
    try {
      await MeditationStatsService.addMeditationTime(testSeconds);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 测试时长记录成功: +${testSeconds}秒'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      print('✅ 测试冥想时长记录完成');
    } catch (e) {
      print('❌ 测试冥想时长记录失败: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 测试失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 重置冥想时长统计
  void _resetMeditationTime() async {
    print('🔄 开始重置冥想时长统计...');
    
    try {
      await MeditationStatsService.resetAllStats();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 冥想时长统计已重置'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      print('✅ 冥想时长统计重置完成');
    } catch (e) {
      print('❌ 重置冥想时长统计失败: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 重置失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Add debug functionality
  void _debugAudio() async {
    if (widget.audioUrl != null) {
      print('🔍 Starting audio playback debug...');
      await AudioService.play(widget.audioUrl!);
    } else {
              print('❌ No audio URL available for debugging');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No audio URL available for debugging')),
        );
    }
  }

      // Test multiple URLs
  void _testMultipleUrls() async {
    print('🧪 Starting multiple audio URL test...');
          // Use simplified test method
    await AudioService.testMultipleUrls();
  }

      // Download test method
  void _testDownload() async {
    if (widget.audioUrl != null) {
      print('📥 Starting download test...');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting download test...')),
      );
      
      try {
        final result = await AudioService.downloadAudio(widget.audioUrl!);
        
        if (result['success']) {
          final fileSize = (result['fileSize'] / 1024 / 1024).toStringAsFixed(2);
          final downloadTime = result['downloadTime'];
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download successful! File size: ${fileSize}MB, Time: ${downloadTime}ms'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
          
          if (result['playbackSuccess'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Downloaded file playback test successful!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download failed: ${result['error']}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download test exception: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No audio URL available for download test'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // 重新生成冥想内容
  Future<void> _regenerateMeditation() async {
    if (_isRegenerating) return;
    
    // 显示重新生成选项对话框
    final String? newDescription = await _showRegenerateDialog();
    if (newDescription == null) return; // 用户取消
    
    setState(() {
      _isRegenerating = true;
    });
    
    try {
      // 停止当前音频播放
      await _stopAudio();
      
      print('🔄 开始重新生成冥想内容...');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在重新生成冥想内容...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // 调用API重新生成冥想内容
      final result = await MeditationApi.generateMeditation(
        userId: FirebaseAuth.instance.currentUser?.uid ?? 'test-user',
        mood: widget.mood,
        description: newDescription, // 使用新的描述
      );
      
      if (mounted) {
        // 更新界面显示新的冥想内容
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MeditationPlayScreen(
              meditationScript: result.script,
              recordId: result.recordId,
              mood: widget.mood,
              audioUrl: result.audioUrl,
              originalDescription: newDescription, // 传递新的描述作为原始描述
            ),
          ),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 冥想内容重新生成成功！'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ 重新生成冥想内容失败: $e');
      if (mounted) {
        setState(() {
          _isRegenerating = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('重新生成失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 显示重新生成选项对话框
  Future<String?> _showRegenerateDialog() async {
    final TextEditingController descriptionController = TextEditingController(
      text: widget.originalDescription ?? '',
    );
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重新生成冥想内容'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '请选择重新生成的方式：',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // 选项1：使用原始描述
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.blue),
              title: const Text('使用原始描述重新生成'),
              subtitle: Text(
                widget.originalDescription ?? '无原始描述',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              onTap: () {
                Navigator.pop(context, widget.originalDescription ?? '重新生成冥想内容');
              },
            ),
            
            // 选项2：输入新描述
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.green),
              title: const Text('输入新的描述'),
              subtitle: const Text('自定义新的冥想需求'),
              onTap: () {
                Navigator.pop(context, 'NEW_DESCRIPTION');
              },
            ),
            
            // 选项3：取消
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('取消'),
              onTap: () {
                Navigator.pop(context, null);
              },
            ),
          ],
        ),
      ),
    ).then((result) async {
      if (result == 'NEW_DESCRIPTION') {
        // 显示输入新描述的对话框
        return showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('输入新的冥想描述'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '请描述您希望的新冥想内容：',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g.: I need a meditation about relaxing body and mind...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  final description = descriptionController.text.trim();
                  if (description.isNotEmpty) {
                    Navigator.pop(context, description);
                  }
                },
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
      return result;
    });
  }

  void _testNetwork() async {
    print('🌐 Starting network connectivity test...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting network connectivity test...')),
    );
    
    try {
      final results = await AudioService.testNetworkConnectivity();
      
      // 统计结果
      final successCount = results.values.where((r) => r['success'] == true).length;
      final totalCount = results.length;
      
      String message;
      Color backgroundColor;
      
      if (successCount == 0) {
        message = '❌ All websites are inaccessible - Network may be completely down or blocked';
        backgroundColor = Colors.red;
      } else if (successCount < totalCount) {
        message = '⚠️ Some websites are inaccessible - Partial blocking detected ($successCount/$totalCount)';
        backgroundColor = Colors.orange;
      } else {
        message = '✅ All websites are accessible - Network is normal ($successCount/$totalCount)';
        backgroundColor = Colors.green;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 8),
        ),
      );
      
      // Print detailed results
      print('\n📊 Detailed test results:');
      results.forEach((url, result) {
        final status = result['success'] ? '✅' : '❌';
        final statusCode = result['statusCode'] ?? 'N/A';
        print('$status $url - 状态码: $statusCode');
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network test exception: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _completeMeditation() {
    final meditationDuration = _startTime != null 
        ? DateTime.now().difference(_startTime!)
        : Duration.zero;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MeditationCompletedScreen(
          meditationDuration: meditationDuration,
          startTime: _startTime?.toString().substring(11, 16),
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 顶部渐变背景
            SliverToBoxAdapter(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryBlue.withOpacity(0.1),
                      AppColors.lightBlue.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.mood} Meditation',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Find your inner peace',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 重新生成按钮
                      IconButton(
                        icon: _isRegenerating 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                              ),
                            )
                          : Icon(Icons.refresh, color: AppColors.primaryBlue),
                        onPressed: _isRegenerating ? null : _regenerateMeditation,
                        tooltip: 'Regenerate meditation content',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 主要内容
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 冥想内容卡片
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.self_improvement,
                                  color: AppColors.primaryBlue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your Guided Meditation',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Take a deep breath and begin',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              widget.meditationScript,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 音频控制卡片
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.music_note,
                                  color: AppColors.primaryBlue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Audio Player',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Listen to your guided meditation',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // 播放控制区域
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                // 播放控制按钮
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.loop,
                                        color: _isLooping ? AppColors.primaryBlue : Colors.grey.shade600,
                                        size: 28,
                                      ),
                                      onPressed: _toggleLoop,
                                      tooltip: 'Loop playback',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.fast_rewind),
                                      onPressed: _isAudioPreloaded ? _rewind : null,
                                      tooltip: _isAudioPreloaded ? 'Rewind 10 seconds' : 'Loading audio...',
                                      iconSize: 28,
                                      color: _isAudioPreloaded ? AppColors.primaryBlue : Colors.grey.shade400,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue,
                                        borderRadius: BorderRadius.circular(50),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primaryBlue.withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          _isPlaying ? Icons.pause : Icons.play_arrow,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                        onPressed: (widget.audioUrl != null && _isAudioPreloaded) ? _togglePlayPause : null,
                                        tooltip: _isPlaying ? 'Pause' : (_isAudioPreloaded ? 'Play' : 'Loading audio...'),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.fast_forward),
                                      onPressed: _isAudioPreloaded ? _fastForward : null,
                                      tooltip: _isAudioPreloaded ? 'Fast forward 10 seconds' : 'Loading audio...',
                                      iconSize: 28,
                                      color: _isAudioPreloaded ? AppColors.primaryBlue : Colors.grey.shade400,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.volume_up),
                                      onPressed: _showVolumeDialog,
                                      tooltip: 'Volume control',
                                      iconSize: 28,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // 进度条和时间显示
                                Column(
                                  children: [
                                    Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: LinearProgressIndicator(
                                        value: _duration.inMilliseconds > 0 
                                          ? _position.inMilliseconds / _duration.inMilliseconds 
                                          : 0.0,
                                        backgroundColor: Colors.transparent,
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (!_isAudioPreloaded && widget.audioUrl != null)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Loading audio...',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Text(
                                        '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')} / ${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 结束冥想按钮
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.timer_off,
                                  color: Colors.orange,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'End Session',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Complete your meditation journey',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _endMeditation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline),
                                  const SizedBox(width: 8),
                                  Text(
                                    'End Meditation',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 重新生成按钮卡片
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.refresh,
                                  color: Colors.orange,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Regenerate Content',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Create a new meditation experience',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isRegenerating ? null : _regenerateMeditation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _isRegenerating 
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.refresh),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isRegenerating ? 'Regenerating...' : 'Regenerate Meditation',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
