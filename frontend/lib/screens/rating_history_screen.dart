import 'package:flutter/material.dart';
import '../services/rating_service.dart';
import '../utils/constants.dart';
import 'test_rating_screen.dart';

class RatingHistoryScreen extends StatefulWidget {
  final String userId;

  const RatingHistoryScreen({
    super.key,
    required this.userId,
  });

  @override
  State<RatingHistoryScreen> createState() => _RatingHistoryScreenState();
}

class _RatingHistoryScreenState extends State<RatingHistoryScreen> with WidgetsBindingObserver {
  List<RatingRecord> _ratings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRatingHistory();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 当应用重新获得焦点时刷新数据
    if (state == AppLifecycleState.resumed) {
      _loadRatingHistory();
    }
  }

  Future<void> _loadRatingHistory() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ratings = await RatingService.getUserRatings(
        userId: widget.userId,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _ratings = ratings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('评分历史'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TestRatingScreen(userId: widget.userId),
                ),
              );
            },
            tooltip: '添加新评分',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRatingHistory,
            tooltip: 'Refresh Rating History',
          ),
        ],
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
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载评分历史...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('加载评分失败: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRatingHistory,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_ratings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Rating Records',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start rating your meditation experiences!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TestRatingScreen(userId: widget.userId),
                  ),
                );
              },
              icon: const Icon(Icons.star),
              label: const Text('Start Rating'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRatingHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ratings.length,
        itemBuilder: (context, index) {
          final rating = _ratings[index];
          return _buildRatingCard(rating);
        },
      ),
    );
  }

  Widget _buildRatingCard(RatingRecord rating) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRatingTypeColor(rating.ratingType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRatingTypeText(rating.ratingType),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getRatingTypeColor(rating.ratingType),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(rating.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < rating.score ? Icons.star : Icons.star_border,
                    size: 20,
                    color: index < rating.score ? Colors.amber : Colors.grey,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '${rating.score}/5',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (rating.comment != null && rating.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                rating.comment!,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ],
            if (rating.feedbackTags != null && rating.feedbackTags!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: rating.feedbackTags!.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.blue,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            
            // 重新评分按钮
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TestRatingScreen(userId: widget.userId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.star, size: 16),
                  label: const Text('重新评分'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: BorderSide(color: AppColors.primaryBlue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRatingTypeColor(RatingType type) {
    switch (type) {
      case RatingType.meditation:
        return Colors.blue;
      case RatingType.mood:
        return Colors.green;
      case RatingType.general:
        return Colors.orange;
    }
  }

  String _getRatingTypeText(RatingType type) {
    switch (type) {
      case RatingType.meditation:
        return 'Meditation Experience';
              case RatingType.mood:
          return 'Mood Record';
              case RatingType.general:
          return 'General Rating';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} 分钟前';
      }
      return '${difference.inHours} 小时前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${date.month}-${date.day}-${date.year}';
    }
  }
}
