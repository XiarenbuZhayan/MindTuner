import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isInitialized = false;

  // 同步获取播放器实例
  static AudioPlayer get player => _player;

  // 初始化播放器
  static Future<void> initialize() async {
    if (!_isInitialized) {
      // 监听播放器状态变化
      _player.playerStateStream.listen((PlayerState state) {
        print('🎵 播放状态: ${state.processingState} - ${state.playing}');
      });
      
      _player.durationStream.listen((Duration? duration) {
        if (duration != null) {
          print('⏱️ 时长: ${duration.inSeconds}秒');
        }
      });
      
      _player.positionStream.listen((Duration position) {
        // 可选：打印播放位置
        // print('📍 位置: ${position.inSeconds}秒');
      });
      
      _isInitialized = true;
      print('✅ AudioService 初始化完成');
    }
  }

  // 🔥 极度简化的播放方法 - 完全信任 just_audio
  static Future<void> play(String url) async {
    print('🎵 开始播放: $url');
    
    await initialize();
    
    try {
      // 停止当前播放
      await _player.stop();
      
      // 设置音频源并播放
      await _player.setUrl(url);
      await _player.play();
      
      print('✅ 播放命令已发送');
      
    } catch (e) {
      print('❌ 播放失败: $e');
      rethrow;
    }
  }

  // 播放控制方法
  static Future<void> pause() async {
    await _player.pause();
    print('⏸️ 暂停播放');
  }
  
  static Future<void> stop() async {
    await _player.stop();
    print('⏹️ 停止播放');
  }

  static Future<void> resume() async {
    await _player.play();
    print('▶️ 继续播放');
  }

  static Future<void> seek(Duration position) async {
    await _player.seek(position);
    print('⏩ 跳转到: ${position.inSeconds}秒');
  }
  
  static Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
    print('🔊 音量设置: ${(volume * 100).toInt()}%');
  }
  
  // 状态获取
  static PlayerState get state => _player.playerState;
  static Future<Duration?> get position async => _player.position;
  static Future<Duration?> get duration async => _player.duration;
  
  // Stream 监听器
  static Stream<Duration> get positionStream => _player.positionStream;
  static Stream<Duration?> get durationStream => _player.durationStream;
  static Stream<PlayerState> get stateStream => _player.playerStateStream;
  
  // 🔥 向后兼容的方法
  static Future<void> diagnosticPlay(String url) async {
    await play(url);
  }
  
  static Future<void> playFromUrl(String url, {String? cacheKey}) async {
    await play(url);
  }
  
  static Future<void> playGoogleStorageAudio(String url) async {
    await play(url);
  }
  
  // 🔥 简化的测试方法
  static Future<void> testMultipleUrls() async {
    final testUrls = [
      'https://www.soundjay.com/misc/sounds/bell-ringing-05.mp3',
      'https://sample-videos.com/zip/10/mp3/SampleAudio_0.4mb_mp3.mp3',
    ];
    
    for (int i = 0; i < testUrls.length; i++) {
      print('\n🧪 测试音频 ${i + 1}/${testUrls.length}');
      print('🔗 ${testUrls[i]}');
      
      try {
        await play(testUrls[i]);
        await Future.delayed(const Duration(seconds: 3));
        await stop();
      } catch (e) {
        print('❌ 测试失败: $e');
      }
    }
  }
  
  // 🔥 下载音频文件方法 - 测试网络连接和是否被墙
  static Future<Map<String, dynamic>> downloadAudio(String url) async {
    print('📥 开始下载音频文件...');
    print('🔗 URL: $url');
    
    final result = <String, dynamic>{
      'success': false,
      'url': url,
      'error': null,
      'filePath': null,
      'fileSize': null,
      'downloadTime': null,
      'statusCode': null,
      'headers': null,
    };
    
    final stopwatch = Stopwatch()..start();
    
    try {
      // 1. 测试网络连接
      print('📡 步骤1: 测试网络连接...');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'audio/mpeg,audio/*,*/*;q=0.9',
        },
      ).timeout(const Duration(seconds: 30));
      
      result['statusCode'] = response.statusCode;
      result['headers'] = response.headers;
      
      print('📊 响应状态码: ${response.statusCode}');
      print('📄 内容类型: ${response.headers['content-type']}');
      print('📏 内容长度: ${response.headers['content-length']}');
      
      if (response.statusCode != 200) {
        result['error'] = 'HTTP状态码错误: ${response.statusCode}';
        print('❌ HTTP状态码错误: ${response.statusCode}');
        return result;
      }
      
      // 2. 检查内容类型
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.startsWith('audio/')) {
        print('⚠️ 警告: 内容类型不是音频文件 ($contentType)');
      }
      
      // 3. 获取音频数据
      print('📦 步骤2: 获取音频数据...');
      final audioBytes = response.bodyBytes;
      final fileSize = audioBytes.length;
      
      print('📊 音频文件大小: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
      
      // 4. 保存到本地文件
      print('💾 步骤3: 保存到本地文件...');
      final tempDir = await getTemporaryDirectory();
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final filePath = '${tempDir.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(audioBytes);
      
      // 5. 验证文件
      if (await file.exists()) {
        final savedFileSize = await file.length();
        print('✅ 文件保存成功: $filePath');
        print('📊 保存的文件大小: ${(savedFileSize / 1024 / 1024).toStringAsFixed(2)}MB');
        
        result['success'] = true;
        result['filePath'] = filePath;
        result['fileSize'] = savedFileSize;
        result['downloadTime'] = stopwatch.elapsedMilliseconds;
        
        print('🎉 下载完成！耗时: ${stopwatch.elapsedMilliseconds}ms');
        
        // 6. 尝试播放下载的文件
        print('🎵 步骤4: 尝试播放下载的文件...');
        try {
          await _player.stop();
          await _player.setFilePath(filePath);
          await _player.play();
          
          await Future.delayed(const Duration(seconds: 2));
          final state = _player.playerState;
          
          if (state.playing) {
            print('✅ 下载的文件播放成功！');
            result['playbackSuccess'] = true;
          } else {
            print('⚠️ 下载的文件播放状态异常: ${state.processingState}');
            result['playbackSuccess'] = false;
          }
          
          await _player.stop();
          
        } catch (e) {
          print('❌ 播放下载的文件失败: $e');
          result['playbackSuccess'] = false;
          result['playbackError'] = e.toString();
        }
        
      } else {
        result['error'] = '文件保存失败';
        print('❌ 文件保存失败');
      }
      
    } catch (e) {
      stopwatch.stop();
      result['error'] = e.toString();
      result['downloadTime'] = stopwatch.elapsedMilliseconds;
      
      print('❌ 下载失败: $e');
      
      // 分析错误类型
      if (e.toString().contains('SocketException')) {
        print('🌐 网络连接错误 - 可能被墙或网络不通');
        result['errorType'] = 'network';
      } else if (e.toString().contains('TimeoutException')) {
        print('⏰ 请求超时 - 网络缓慢或被墙');
        result['errorType'] = 'timeout';
      } else if (e.toString().contains('HttpException')) {
        print('🌐 HTTP错误 - 服务器问题或被墙');
        result['errorType'] = 'http';
      } else {
        print('❓ 其他错误');
        result['errorType'] = 'other';
      }
    }
    
    stopwatch.stop();
    return result;
  }
  
  // 🔥 网络连接测试方法
  static Future<Map<String, dynamic>> testNetworkConnectivity() async {
    print('🌐 开始网络连接测试...');
    
    final testUrls = [
      'https://www.google.com',
      'https://www.baidu.com',
      'https://www.bing.com',
      'https://storage.googleapis.com',
    ];
    
    final results = <String, dynamic>{};
    
    for (final url in testUrls) {
      print('\n🔍 测试: $url');
      
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ).timeout(const Duration(seconds: 10));
        
        results[url] = {
          'success': response.statusCode == 200,
          'statusCode': response.statusCode,
          'responseTime': '正常',
        };
        
        print('✅ 成功 - 状态码: ${response.statusCode}');
        
      } catch (e) {
        results[url] = {
          'success': false,
          'error': e.toString(),
          'responseTime': '超时/失败',
        };
        
        print('❌ 失败: $e');
      }
    }
    
    // 分析结果
    final successCount = results.values.where((r) => r['success'] == true).length;
    final totalCount = results.length;
    
    print('\n📊 网络测试总结:');
    print('   成功: $successCount/$totalCount');
    
    if (successCount == 0) {
      print('❌ 所有网站都无法访问 - 可能网络完全断开或被墙');
    } else if (successCount < totalCount) {
      print('⚠️ 部分网站无法访问 - 可能部分被墙');
    } else {
      print('✅ 所有网站都可以访问 - 网络正常');
    }
    
    return results;
  }

  // 🔥 详细的网络诊断方法 - 检查代理设置
  static Future<Map<String, dynamic>> diagnoseNetworkIssues() async {
    print('🔍 开始详细网络诊断...');
    
    final diagnosis = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'tests': <String, dynamic>{},
    };
    
    // 1. 测试基本网络连接
    print('\n📡 测试1: 基本网络连接');
    try {
      final response = await http.get(
        Uri.parse('https://www.baidu.com'),
        headers: {'User-Agent': 'Flutter/1.0'},
      ).timeout(const Duration(seconds: 5));
      
      diagnosis['tests']['basic_connectivity'] = {
        'success': true,
        'statusCode': response.statusCode,
        'message': '基本网络连接正常',
      };
      print('✅ 基本网络连接正常');
    } catch (e) {
      diagnosis['tests']['basic_connectivity'] = {
        'success': false,
        'error': e.toString(),
        'message': '基本网络连接失败',
      };
      print('❌ 基本网络连接失败: $e');
    }
    
    // 2. 测试Google连接
    print('\n🌐 测试2: Google连接');
    try {
      final response = await http.get(
        Uri.parse('https://www.google.com'),
        headers: {'User-Agent': 'Flutter/1.0'},
      ).timeout(const Duration(seconds: 10));
      
      diagnosis['tests']['google_connectivity'] = {
        'success': true,
        'statusCode': response.statusCode,
        'message': 'Google连接正常',
      };
      print('✅ Google连接正常');
    } catch (e) {
      diagnosis['tests']['google_connectivity'] = {
        'success': false,
        'error': e.toString(),
        'message': 'Google连接失败 - 可能需要代理',
      };
      print('❌ Google连接失败: $e');
    }
    
    // 3. 测试DNS解析
    print('\n🔍 测试3: DNS解析');
    try {
      final response = await http.get(
        Uri.parse('https://8.8.8.8'),
        headers: {'User-Agent': 'Flutter/1.0'},
      ).timeout(const Duration(seconds: 5));
      
      diagnosis['tests']['dns_resolution'] = {
        'success': true,
        'statusCode': response.statusCode,
        'message': 'DNS解析正常',
      };
      print('✅ DNS解析正常');
    } catch (e) {
      diagnosis['tests']['dns_resolution'] = {
        'success': false,
        'error': e.toString(),
        'message': 'DNS解析可能有问题',
      };
      print('❌ DNS解析失败: $e');
    }
    
    // 4. 测试代理相关网站
    print('\n🔧 测试4: 代理相关网站');
    final proxyTestUrls = [
      'https://httpbin.org/ip',
      'https://api.ipify.org?format=json',
    ];
    
    for (final url in proxyTestUrls) {
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {'User-Agent': 'Flutter/1.0'},
        ).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          print('✅ $url 访问成功');
          diagnosis['tests']['proxy_test_$url'] = {
            'success': true,
            'statusCode': response.statusCode,
            'response': response.body,
            'message': '代理测试成功',
          };
        } else {
          print('⚠️ $url 状态码异常: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ $url 访问失败: $e');
        diagnosis['tests']['proxy_test_$url'] = {
          'success': false,
          'error': e.toString(),
          'message': '代理测试失败',
        };
      }
    }
    
    // 5. 分析结果
    final successCount = diagnosis['tests'].values.where((t) => t['success'] == true).length;
    final totalCount = diagnosis['tests'].length;
    
    diagnosis['summary'] = {
      'total_tests': totalCount,
      'successful_tests': successCount,
      'success_rate': '${(successCount / totalCount * 100).toStringAsFixed(1)}%',
    };
    
    print('\n📊 网络诊断总结:');
    print('   总测试数: $totalCount');
    print('   成功测试: $successCount');
    print('   成功率: ${(successCount / totalCount * 100).toStringAsFixed(1)}%');
    
    // 提供建议
    if (diagnosis['tests']['google_connectivity']?['success'] == false) {
      print('\n💡 建议:');
      print('   1. 检查模拟器代理设置是否正确');
      print('   2. 确认代理服务器是否正常工作');
      print('   3. 尝试重启模拟器');
      print('   4. 检查防火墙设置');
    }
    
    return diagnosis;
  }
}