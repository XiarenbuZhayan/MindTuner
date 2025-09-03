import 'package:flutter/material.dart';
import '../widgets/mark.dart';
import '../utils/constants.dart';
import '../services/rating_service.dart';
import 'rating_history_screen.dart';

class TestRatingScreen extends StatefulWidget {
  final String userId;
  
  const TestRatingScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<TestRatingScreen> createState() => _TestRatingScreenState();
}

class _TestRatingScreenState extends State<TestRatingScreen> {
  bool _isTestingConnection = false;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    _testBackendConnection();
  }

  Future<void> _testBackendConnection() async {
    if (!mounted) return;
    
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = '正在测试后端连接...';
    });

    try {
      final isConnected = await RatingService.testConnection();
      if (mounted) {
        setState(() {
          _connectionStatus = isConnected ? '✅ 后端连接正常' : '❌ 后端连接失败';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionStatus = '❌ 连接测试异常: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
        });
      }
    }
  }

  Future<void> _testHealthCheck() async {
    if (!mounted) return;
    
    try {
      final result = await RatingService.healthCheck();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('健康检查成功: ${result.toString()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('健康检查失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 评分成功后的处理
  void _onRatingSuccess() {
    // 跳转到评分历史界面
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RatingHistoryScreen(
          userId: widget.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditation Experience Rating'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 连接状态显示
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          '后端连接状态',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_isTestingConnection)
                          const CircularProgressIndicator()
                        else if (_connectionStatus != null)
                          Text(
                            _connectionStatus!,
                            style: TextStyle(
                              color: _connectionStatus!.contains('✅') 
                                ? Colors.green 
                                : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: _testBackendConnection,
                              child: const Text('重新测试'),
                            ),
                            ElevatedButton(
                              onPressed: _testHealthCheck,
                              child: const Text('健康检查'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                const Text(
                  'Rate Your Meditation Experience',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 直接显示评分组件
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: MarkWidget(
                        ratingType: RatingType.meditation,
                                contentTitle: "Deep Meditation Experience",
        contentText: "In this meditation, you will experience inner peace and tranquility. Through deep breathing and mindfulness practice, let your body and mind achieve complete relaxation. Focus on this present moment, feel the inner harmony and balance. This is a wonderful spiritual journey that helps you release stress and find inner peace.",
                        contentMood: "peaceful",
                        onRatingSubmitted: (rating, comment) {
                          // 显示成功消息，但不立即跳转
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Rating submitted successfully: $rating stars'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        onCancel: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User cancelled rating'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        onRatingSuccess: _onRatingSuccess, // 添加评分成功回调
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
