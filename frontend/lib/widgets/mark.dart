import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/rating_service.dart' as rating_api;
import '../services/rating_state_service.dart';
import '../services/feedback_optimization_service.dart' as feedback;

class MarkWidget extends StatefulWidget {
  final rating_api.RatingType ratingType;
  final Function(int rating, String comment)? onRatingSubmitted;
  final VoidCallback? onCancel;
  final VoidCallback? onRatingSuccess; // 新增：评分成功回调
  final String? contentTitle; // 生成内容的标题
  final String? contentText;  // 生成的内容文本
  final String? contentMood;  // 生成内容的心情
  final String? recordId; // 冥想记录ID
  final String? userId; // 用户ID

  const MarkWidget({
    super.key,
    this.ratingType = rating_api.RatingType.general,
    this.onRatingSubmitted,
    this.onCancel,
    this.onRatingSuccess, // 新增参数
    this.contentTitle,
    this.contentText,
    this.contentMood,
    this.recordId,
    this.userId,
  });

  @override
  State<MarkWidget> createState() => _MarkWidgetState();
}

class _MarkWidgetState extends State<MarkWidget> {
  int _currentRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _message;
  bool _showThankYouPage = false; // 新增：控制感谢页面显示
  rating_api.RatingRecord? _submittedRating; // 新增：存储已提交的评分
  
  @override
  void initState() {
    super.initState();
    _loadRatingState();
  }
  
  // 新增：加载评分状态
  Future<void> _loadRatingState() async {
    try {
      // 检查特定记录是否已评分
      if (widget.recordId != null) {
        final hasRated = await RatingStateService.isRecordRated(widget.recordId!);
        if (hasRated) {
          final recordRating = await RatingStateService.getRecordRating(widget.recordId!);
          print('🔍 加载记录评分: ${recordRating?.score}');
          if (recordRating != null) {
            setState(() {
              _submittedRating = recordRating;
              _currentRating = recordRating.score; // 设置当前评分为已保存的评分
              _showThankYouPage = true;
            });
            print('🔍 设置加载的评分: ${_submittedRating?.score}');
          }
        }
      }
    } catch (e) {
      print('加载评分状态失败: $e');
    }
  }

  Future<void> _submitRating() async {
    if (_currentRating == 0) {
      setState(() {
        _message = 'Please select a rating first';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      if (widget.onRatingSubmitted != null) {
        widget.onRatingSubmitted!(_currentRating, _commentController.text);
        // 创建模拟的评分记录来显示感谢页面
        print('🔍 创建评分记录，评分值: $_currentRating');
        final mockRating = rating_api.RatingRecord(
          ratingId: 'mock_${DateTime.now().millisecondsSinceEpoch}',
          userId: 'default_user',
          ratingType: widget.ratingType,
          score: _currentRating,
          comment: _commentController.text.isNotEmpty ? _commentController.text : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        print('🔍 创建的评分记录: ${mockRating.score}');
        
        setState(() {
          _submittedRating = mockRating;
          _showThankYouPage = true; // 显示感谢页面
        });
        print('🔍 设置评分状态，评分值: ${_submittedRating?.score}');
        
        // 保存评分状态
        await RatingStateService.saveRatingState(
          hasRated: true,
          ratingRecord: mockRating,
        );
        
        // 保存特定记录的评分状态
        if (widget.recordId != null) {
          await RatingStateService.saveRecordRatingState(
            recordId: widget.recordId!,
            hasRated: true,
            ratingRecord: mockRating,
          );
          print('🔍 保存记录评分状态，评分值: ${mockRating.score}');
        }
        
        // 保存详细的评分记录用于优化
        if (widget.recordId != null && widget.contentText != null) {
          final detailedRating = feedback.RatingRecord(
            recordId: widget.recordId!,
            score: _currentRating,
            comment: _commentController.text.isNotEmpty ? _commentController.text : null,
            createdAt: DateTime.now(),
            meditationScript: widget.contentText!,
            actualDuration: _estimateDuration(widget.contentText!),
          );
          await feedback.FeedbackOptimizationService.saveRatingRecord(detailedRating);
        }
        
        // 不在这里return，让finally块执行来重置_isSubmitting状态
      } else {
        print('🌟 开始提交评分...');
        print('评分: $_currentRating, 类型: ${widget.ratingType}, 评论: ${_commentController.text}');
        
        final result = await rating_api.RatingService.createRating(
          userId: widget.userId ?? 'default_user',
          ratingType: widget.ratingType,
          score: _currentRating,
          comment: _commentController.text.isNotEmpty ? _commentController.text : null,
        );
        
        print('✅ 评分提交成功: ${result.ratingId}');
        
        setState(() {
          _submittedRating = result;
          _showThankYouPage = true; // 显示感谢页面
        });
        
        // 保存评分状态
        await RatingStateService.saveRatingState(
          hasRated: true,
          ratingRecord: result,
        );
        
        // 保存特定记录的评分状态
        if (widget.recordId != null) {
          await RatingStateService.saveRecordRatingState(
            recordId: widget.recordId!,
            hasRated: true,
            ratingRecord: result,
          );
          print('🔍 保存记录评分状态，评分值: ${result.score}');
        }
        
        // 保存详细的评分记录用于优化
        if (widget.recordId != null && widget.contentText != null) {
          final detailedRating = feedback.RatingRecord(
            recordId: widget.recordId!,
            score: _currentRating,
            comment: _commentController.text.isNotEmpty ? _commentController.text : null,
            createdAt: DateTime.now(),
            meditationScript: widget.contentText!,
            actualDuration: _estimateDuration(widget.contentText!),
          );
          await feedback.FeedbackOptimizationService.saveRatingRecord(detailedRating);
        }
        
        // 注意：不在这里调用 onRatingSuccess，让用户先看到感谢页面
        // 用户点击"查看历史"按钮时再调用
      }
    } catch (e) {
      print('❌ 评分提交失败: $e');
      setState(() {
        _message = 'Rating submission failed: $e';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // 新增：感谢页面组件
  Widget _buildThankYouPage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 成功图标
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: Colors.green,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 感谢标题
          const Text(
            'Thank you for your rating!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          
          const SizedBox(height: 10),
          
          // 评分信息
          if (_submittedRating != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < _submittedRating!.score ? Icons.star : Icons.star_border,
                    size: 24,
                    color: index < _submittedRating!.score ? Colors.amber : Colors.grey,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '${_submittedRating!.score}/5',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 评分类型
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getRatingTypeColor(_submittedRating!.ratingType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getRatingTypeText(_submittedRating!.ratingType),
                style: TextStyle(
                  fontSize: 14,
                  color: _getRatingTypeColor(_submittedRating!.ratingType),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 评论（如果有）
            if (_submittedRating!.comment != null && _submittedRating!.comment!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _submittedRating!.comment!,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
          
          // 感谢信息
          const Text(
            'Your feedback is very important to us,\nhelping us provide a better meditation experience!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    // 清除保存的评分状态
                    await RatingStateService.clearRatingState();
                    if (widget.recordId != null) {
                      await RatingStateService.clearRecordRatingState(widget.recordId!);
                    }
                    
                    setState(() {
                      _showThankYouPage = false;
                      _submittedRating = null;
                      _currentRating = 0;
                      _commentController.clear();
                      _message = null;
                    });
                  },
                  child: const Text('Rate Again'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // 跳转到评分历史页面
                    if (widget.onRatingSuccess != null) {
                      widget.onRatingSuccess!();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('查看历史'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRatingTypeColor(rating_api.RatingType type) {
    switch (type) {
      case rating_api.RatingType.meditation:
        return Colors.blue;
      case rating_api.RatingType.mood:
        return Colors.green;
      case rating_api.RatingType.general:
        return Colors.orange;
    }
  }

  String _getRatingTypeText(rating_api.RatingType type) {
    switch (type) {
      case rating_api.RatingType.meditation:
        return 'Meditation Experience';
              case rating_api.RatingType.mood:
          return 'Mood Record';
              case rating_api.RatingType.general:
          return 'General Rating';
    }
  }
  
  // 估算冥想时长（分钟）
  int _estimateDuration(String script) {
    // 简单的估算：每100个字符约1分钟
    final charCount = script.length;
    final estimatedMinutes = (charCount / 100).round();
    return estimatedMinutes.clamp(1, 30); // 限制在1-30分钟之间
  }

  Widget _buildContentDisplay() {
    if (widget.contentTitle == null && widget.contentText == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Generated Content',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const Spacer(),
              if (widget.contentMood != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getMoodEmoji(widget.contentMood!) + ' ' + widget.contentMood!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          if (widget.contentTitle != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.contentTitle!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
          ],
          if (widget.contentText != null) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Text(
                  widget.contentText!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'joyful':
      case 'excited':
        return '😊';
      case 'sad':
      case 'depressed':
      case 'melancholy':
        return '😢';
      case 'anxious':
      case 'worried':
      case 'stressed':
        return '😰';
      case 'angry':
      case 'frustrated':
        return '😠';
      case 'calm':
      case 'peaceful':
      case 'relaxed':
        return '😌';
      default:
        return '😐';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 生成内容显示
        _buildContentDisplay(),
        
        // 根据状态显示不同内容
        if (_showThankYouPage) ...[
          // 显示感谢页面
          _buildThankYouPage(),
        ] else ...[
          // 显示评分组件
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rate Your Experience',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 20),
            
                // 星星评分
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _currentRating ? Icons.star : Icons.star_border,
                        color: index < _currentRating ? Colors.amber : Colors.grey.shade300,
                        size: 40,
                      ),
                      onPressed: () {
                        setState(() {
                          _currentRating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                
                const SizedBox(height: 20),
                
                // 评论输入框
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'share your thoughts...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  minLines: 3,
                  maxLines: 5,
                ),
                
                const SizedBox(height: 20),
                
                // 消息提示
                if (_message != null)
                  Text(
                    _message!,
                    style: TextStyle(
                      color: _message!.contains('感谢您的反馈') ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // 按钮
                Row(
                  children: [
                    if (widget.onCancel != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onCancel,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRating,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
