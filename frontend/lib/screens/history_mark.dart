import 'package:flutter/material.dart';
import '../widgets/mark.dart';
import '../utils/constants.dart';
import '../services/rating_service.dart';

class MarkScreen extends StatefulWidget {
  final RatingType? initialRatingType;
  final String? contentTitle;
  final String? contentText;
  final String? contentMood;
  final String? meditationRecordId;
  final String? recordId;
  final String? userId;
  
  const MarkScreen({
    Key? key, 
    this.initialRatingType,
    this.contentTitle,
    this.contentText,
    this.contentMood,
    this.meditationRecordId,
    this.recordId,
    this.userId,
  }) : super(key: key);

  @override
  State<MarkScreen> createState() => _MarkScreenState();
}

class _MarkScreenState extends State<MarkScreen> {
  RatingType _selectedRatingType = RatingType.general;

  @override
  void initState() {
    super.initState();
    if (widget.initialRatingType != null) {
      _selectedRatingType = widget.initialRatingType!;
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rating'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 评分类型选择
                if (widget.initialRatingType == null) ...[
                  _buildRatingTypeSelector(),
                  const SizedBox(height: 20),
                ],
                
                // 评分组件
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: MarkWidget(
                      ratingType: _selectedRatingType,
                      onRatingSubmitted: _handleRatingSubmitted,
                      onCancel: () {
                        Navigator.of(context).pop();
                      },
                      contentTitle: widget.contentTitle,
                      contentText: widget.contentText,
                      contentMood: widget.contentMood,
                      recordId: widget.recordId,
                      userId: widget.userId,
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

  Widget _buildRatingTypeSelector() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Rating Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildRatingTypeChip(
                  RatingType.meditation,
                  'Meditation Experience',
                  Icons.self_improvement,
                ),
                _buildRatingTypeChip(
                  RatingType.mood,
                  'Mood Record',
                  Icons.mood,
                ),
                _buildRatingTypeChip(
                  RatingType.general,
                  'General Rating',
                  Icons.star,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingTypeChip(RatingType type, String label, IconData icon) {
    final isSelected = _selectedRatingType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRatingType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.white : AppColors.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.primaryBlue,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleRatingSubmitted(int rating, String comment) async {
    try {
      print('🌟 历史页面开始提交评分...');
      
      // 使用评分服务提交到后端
      final result = await RatingService.createRating(
        userId: widget.userId ?? 'default_user', // 使用传入的用户ID
        ratingType: _selectedRatingType,
        score: rating,
        comment: comment.isNotEmpty ? comment : null,
      );
      
      print('✅ 历史页面评分提交成功: ${result.ratingId}');
      
      // 显示成功消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Rating submitted successfully! Your rating: $rating stars'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        
        // 延迟后返回上一页
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      print('❌ 历史页面评分提交失败: $e');
      
      // 显示详细错误消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text('Rating submission failed'),
                  ],
                ),
                const SizedBox(height: 4),
                Text('错误详情: $e', style: const TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '重试',
              textColor: Colors.white,
              onPressed: () {
                _handleRatingSubmitted(rating, comment);
              },
            ),
          ),
        );
      }
    }
  }
}