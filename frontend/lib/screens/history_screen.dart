import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/screens/history_mark.dart';
import 'package:frontend/services/rating_service.dart';
import 'package:frontend/services/rating_state_service.dart';
import '../services/meditation_api.dart';
import 'meditation_screens.dart';
import '../utils/constants.dart';

class HistoryScreen extends StatefulWidget {
  final String? userId;
  final String? userEmail;
  final String? userDisplayName;
  
  const HistoryScreen({
    super.key,
    this.userId,
    this.userEmail,
    this.userDisplayName,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, List<MeditationHistoryItem>> _groupedRecords = {};
  bool _isLoading = false;
  String? _error;
  
  // 使用传入的用户ID
  String get _uid => widget.userId ?? 'test-user';

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    if (_uid == 'test-user') {
      if (mounted) {
        setState(() {
          _error = 'Please login to view history records';
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      print('📚 Starting to load history records, User ID: $_uid');
      
      final groupedData = await MeditationApi.getUserMeditationHistoryGrouped(
        userId: _uid,
        limit: 100,
      );
      
      // 为每个记录添加评分状态
      final updatedGroupedData = <String, List<MeditationHistoryItem>>{};
      
      for (final entry in groupedData.entries) {
        final dateStr = entry.key;
        final records = entry.value;
        
        final updatedRecords = <MeditationHistoryItem>[];
        for (final record in records) {
          // 检查该记录是否已评分
          final isRated = await RatingStateService.isRecordRated(record.recordId);
          
          // 如果已评分，获取实际的评分记录
          int? actualScore;
          if (isRated) {
            final ratingRecord = await RatingStateService.getRecordRating(record.recordId);
            actualScore = ratingRecord?.score;
            print('🔍 记录 ${record.recordId} 的实际评分: $actualScore');
          }
          
          // 创建新的记录对象，包含评分状态
          final updatedRecord = MeditationHistoryItem(
            recordId: record.recordId,
            mood: record.mood,
            context: record.context,
            script: record.script,
            createdAt: record.createdAt,
            isRegenerated: record.isRegenerated,
            score: actualScore, // 使用实际评分，如果未评分则为null
            feedback: record.feedback,
            audioUrl: record.audioUrl,
          );
          
          updatedRecords.add(updatedRecord);
        }
        
        updatedGroupedData[dateStr] = updatedRecords;
      }
      
      if (mounted) {
        setState(() {
          _groupedRecords = updatedGroupedData;
          _isLoading = false;
        });
      }
      
      print('✅ History records loaded successfully, total ${_groupedRecords.length} date groups');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to get grouped history records: $e';
          _isLoading = false;
        });
      }
      print('❌ Failed to load history records: $e');
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final recordDate = DateTime(date.year, date.month, date.day);

             if (recordDate == today) {
         return 'Today';
       } else if (recordDate == yesterday) {
         return 'Yesterday';
       } else {
         return '${date.month}/${date.day}';
       }
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'joyful':
      case 'excited':
        return Colors.green;
      case 'sad':
      case 'depressed':
      case 'melancholy':
        return Colors.blue;
      case 'anxious':
      case 'worried':
      case 'stressed':
        return Colors.orange;
      case 'angry':
      case 'frustrated':
        return Colors.red;
      case 'calm':
      case 'peaceful':
      case 'relaxed':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

void _onHistoryItemTap(MeditationHistoryItem record) async {
  // 检查是否已评分
  final hasRated = await RatingStateService.isRecordRated(record.recordId);
  
  if (hasRated) {
    // 如果已评分，显示评分详情
    final recordRating = await RatingStateService.getRecordRating(record.recordId);
    if (recordRating != null) {
      _showRatingDetails(record, recordRating);
    }
  } else {
    // 如果未评分，跳转到评分界面
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkScreen(
          initialRatingType: RatingType.meditation,
          contentTitle: record.context,
          contentText: record.script,
          contentMood: record.mood,
          meditationRecordId: record.recordId, // Pass record ID for linking
          recordId: record.recordId, // 传递recordId给MarkWidget
          userId: _uid, // 传递用户ID
        ),
      ),
    );
    _loadHistoryData(); // Refresh history after rating
  }
}

  void _onRefresh() {
    _loadHistoryData();
  }

  void _showRatingDetails(MeditationHistoryItem record, RatingRecord ratingRecord) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rating Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('内容: ${record.context}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Rating: '),
                ...List.generate(5, (index) {
                  return Icon(
                    index < ratingRecord.score ? Icons.star : Icons.star_border,
                    size: 20,
                    color: index < ratingRecord.score ? Colors.amber : Colors.grey,
                  );
                }),
                const SizedBox(width: 8),
                Text('${ratingRecord.score}/5'),
              ],
            ),
            if (ratingRecord.comment != null && ratingRecord.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('评论: ${ratingRecord.comment}'),
            ],
            const SizedBox(height: 8),
            Text('Rating Time: ${_formatDate(ratingRecord.createdAt.toString())}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('加载中...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Load failed: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_groupedRecords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No meditation records',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Start your first meditation!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistoryData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groupedRecords.length,
        itemBuilder: (context, index) {
          final dateStr = _groupedRecords.keys.elementAt(index);
          final records = _groupedRecords[dateStr]!;
          
          return _buildHistoryDate(dateStr, records);
        },
      ),
    );
  }

  Widget _buildHistoryDate(String dateStr, List<MeditationHistoryItem> records) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          _formatDate(dateStr),
          style: const TextStyle(
            fontFamily: 'consolas',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 126, 159, 186),
          ),
        ),
        subtitle: Text(
          '${records.length} meditations',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        children: records.map((record) => _buildHistoryItem(record)).toList(),
      ),
    );
  }

  Widget _buildHistoryItem(MeditationHistoryItem record) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getMoodColor(record.mood).withOpacity(0.2),
        child: Text(
          _getMoodEmoji(record.mood),
          style: const TextStyle(fontSize: 20),
        ),
      ),
      title: Text(
        record.context,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatTime(record.createdAt),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          if (record.score != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Rated',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ...List.generate(5, (index) {
                  return Icon(
                    index < record.score! ? Icons.star : Icons.star_border,
                    size: 16,
                    color: index < record.score! ? Colors.amber : Colors.grey,
                  );
                }),
              ],
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (record.isRegenerated)
            const Icon(
              Icons.refresh,
              size: 16,
              color: Colors.blue,
            ),
          const SizedBox(width: 8),
          if (record.score != null)
            const Icon(
              Icons.check_circle,
              size: 16,
              color: Colors.green,
            )
          else
            const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => _onHistoryItemTap(record),
    );
  }
} 