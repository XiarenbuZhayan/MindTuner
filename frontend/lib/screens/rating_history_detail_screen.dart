import 'package:flutter/material.dart';
import '../services/feedback_optimization_service.dart';
import '../utils/constants.dart';

class RatingHistoryDetailScreen extends StatefulWidget {
  const RatingHistoryDetailScreen({super.key});

  @override
  State<RatingHistoryDetailScreen> createState() => _RatingHistoryDetailScreenState();
}

class _RatingHistoryDetailScreenState extends State<RatingHistoryDetailScreen> {
  List<RatingRecord> _ratingHistory = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final history = await FeedbackOptimizationService.getRatingHistory();
      final stats = await FeedbackOptimizationService.getRatingStatistics();
      
      setState(() {
        _ratingHistory = history;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('加载评分历史失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rating History Details'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ratingHistory.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatisticsCard(),
                        const SizedBox(height: 20),
                        _buildRatingHistoryList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Rating Records',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Start meditating and rating to view history',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rating Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Rating',
                    '${_statistics['totalRatings'] ?? 0}',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '平均分',
                    '${(_statistics['averageScore'] ?? 0.0).toStringAsFixed(1)}',
                    Icons.analytics,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '趋势',
                    _getTrendText(_statistics['recentTrend'] ?? 'stable'),
                    _getTrendIcon(_statistics['recentTrend'] ?? 'stable'),
                    _getTrendColor(_statistics['recentTrend'] ?? 'stable'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRatingDistribution(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingDistribution() {
    final distribution = _statistics['ratingDistribution'] as Map<String, dynamic>? ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
                      'Rating Distribution',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(5, (index) {
          final rating = 5 - index;
          final count = (distribution[rating.toString()] as int?) ?? 0;
          final total = (_statistics['totalRatings'] as int?) ?? 1;
          final percentage = total > 0 ? (count / total * 100) : 0.0;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Row(
                    children: [
                      Text('$rating星'),
                      const SizedBox(width: 4),
                      Icon(Icons.star, size: 16, color: Colors.amber),
                    ],
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      rating >= 4 ? Colors.green : rating >= 3 ? Colors.orange : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRatingHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
                      'Rating Records',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._ratingHistory.map((record) => _buildRatingCard(record)).toList(),
      ],
    );
  }

  Widget _buildRatingCard(RatingRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Row(
          children: [
            ...List.generate(5, (index) {
              return Icon(
                index < record.score ? Icons.star : Icons.star_border,
                size: 20,
                color: index < record.score ? Colors.amber : Colors.grey,
              );
            }),
            const SizedBox(width: 8),
            Text(
              '${record.score}/5',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Duration: ${record.actualDuration} minutes',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Rating Time: ${_formatDate(record.createdAt)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (record.comment != null && record.comment!.isNotEmpty) ...[
                  const Text(
                    '评论:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(record.comment!),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Meditation Content:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                  ),
                  child: Text(
                    record.meditationScript,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getTrendText(String trend) {
    switch (trend) {
      case 'improving':
        return 'Increasing';
      case 'declining':
        return 'Declining';
      default:
        return 'Stable';
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'improving':
        return Icons.trending_up;
      case 'declining':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'improving':
        return Colors.green;
      case 'declining':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
