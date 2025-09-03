import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/enhanced_meditation_api.dart';
import '../services/rating_service.dart';
import '../widgets/mark.dart';

class EnhancedMeditationScreen extends StatefulWidget {
  final String userId;
  
  const EnhancedMeditationScreen({
    super.key,
    required this.userId,
  });

  @override
  State<EnhancedMeditationScreen> createState() => _EnhancedMeditationScreenState();
}

class _EnhancedMeditationScreenState extends State<EnhancedMeditationScreen> {
  final TextEditingController _moodController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isGenerating = false;
  String? _generatedScript;
  String? _audioUrl;
  Map<String, dynamic>? _feedbackAnalysis;
  List<Map<String, dynamic>> _feedbackHistory = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFeedbackAnalysis();
  }

  @override
  void dispose() {
    _moodController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedbackAnalysis() async {
    try {
      final analysis = await EnhancedMeditationApi.getUserFeedbackAnalysis(widget.userId);
      final history = await EnhancedMeditationApi.getUserFeedbackHistory(widget.userId, limit: 5);
      
      if (mounted) {
        setState(() {
          _feedbackAnalysis = analysis;
          _feedbackHistory = List<Map<String, dynamic>>.from(history['feedback_history'] ?? []);
        });
      }
    } catch (e) {
      print('加载反馈分析失败: $e');
    }
  }

  Future<void> _generateEnhancedMeditation() async {
    if (_moodController.text.isEmpty || _descriptionController.text.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Please fill in mood and description';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isGenerating = true;
        _errorMessage = null;
        _generatedScript = null;
        _audioUrl = null;
      });
    }

    try {
      final result = await EnhancedMeditationApi.generateEnhancedMeditation(
        userId: widget.userId,
        mood: _moodController.text,
        description: _descriptionController.text,
      );

      if (mounted) {
        setState(() {
          _generatedScript = result['meditation_script'];
          _audioUrl = result['audio_url'];
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '生成失败: $e';
          _isGenerating = false;
        });
      }
    }
  }

  Widget _buildFeedbackAnalysisCard() {
    if (_feedbackAnalysis == null || _feedbackAnalysis!['has_feedback'] == false) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  const Text(
                    '反馈分析',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'No feedback records, generated content will be based on standard template',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final analysis = _feedbackAnalysis!['analysis'];
    final latestFeedback = _feedbackAnalysis!['latest_feedback'];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  '智能反馈分析',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '满意度: ${(analysis['overall_satisfaction'] * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 最新反馈
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '最新反馈',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < latestFeedback['rating_score'] ? Icons.star : Icons.star_border,
                          size: 16,
                          color: index < latestFeedback['rating_score'] ? Colors.amber : Colors.grey,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text('${latestFeedback['rating_score']}/5'),
                    ],
                  ),
                  if (latestFeedback['rating_comment'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '评论: ${latestFeedback['rating_comment']}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 优化建议
            if (analysis['key_issues'] != null && analysis['key_issues'].isNotEmpty) ...[
              const Text(
                '识别的问题',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...analysis['key_issues'].map<Widget>((issue) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(issue)),
                  ],
                ),
              )).toList(),
              const SizedBox(height: 16),
            ],
            
            if (analysis['improvement_suggestions'] != null && analysis['improvement_suggestions'].isNotEmpty) ...[
              const Text(
                '优化建议',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...analysis['improvement_suggestions'].map<Widget>((suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(suggestion)),
                  ],
                ),
              )).toList(),
              const SizedBox(height: 16),
            ],
            
            // 用户偏好
            if (analysis['user_preferences'] != null) ...[
              const Text(
                '用户偏好',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                                          Text('Content Style: ${analysis['user_preferences']['content_style'] ?? 'Not analyzed'}'),
                      Text('Guidance Tone: ${analysis['user_preferences']['guidance_tone'] ?? 'Not analyzed'}'),
                    Text('Duration Preference: ${analysis['user_preferences']['duration_preference'] ?? 'Not analyzed'}'),
                                          Text('Personalization Level: ${analysis['user_preferences']['personalization_level'] ?? 'Not analyzed'}'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackHistoryCard() {
    if (_feedbackHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  '反馈历史',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._feedbackHistory.take(3).map((feedback) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < feedback['rating_score'] ? Icons.star : Icons.star_border,
                      size: 14,
                      color: index < feedback['rating_score'] ? Colors.amber : Colors.grey,
                    );
                  }),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feedback['mood'] ?? 'Unknown mood',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    feedback['created_at']?.toString().substring(0, 10) ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedContent() {
    if (_generatedScript == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  'Feedback-optimized meditation content',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'AI优化',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                _generatedScript!,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 评分组件
            MarkWidget(
              ratingType: RatingType.meditation,
              contentTitle: 'Feedback-optimized meditation',
              contentText: _generatedScript,
              contentMood: _moodController.text,
              onRatingSubmitted: (rating, comment) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Thank you for your feedback! AI will continue to optimize content based on your rating.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intelligent Meditation Generation'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 反馈分析卡片
            _buildFeedbackAnalysisCard(),
            
            // 反馈历史卡片
            _buildFeedbackHistoryCard(),
            
            // 生成表单
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.create, color: AppColors.primaryBlue),
                        const SizedBox(width: 8),
                        const Text(
                          'Generate Optimized Meditation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _moodController,
                      decoration: const InputDecoration(
                        labelText: 'Current Mood',
                        hintText: 'e.g.: anxious, calm, tired...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: '详细描述',
                        hintText: '描述您当前的状态和需求...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isGenerating ? null : _generateEnhancedMeditation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isGenerating
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('AI正在分析反馈并生成优化内容...'),
                                ],
                              )
                            : const Text('Generate Feedback-optimized Meditation'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 生成的内容
            _buildGeneratedContent(),
          ],
        ),
      ),
    );
  }
}
