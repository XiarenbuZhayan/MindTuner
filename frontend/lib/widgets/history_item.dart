import 'package:flutter/material.dart';
import '../models/meditation_session.dart';

class HistoryItem extends StatelessWidget {
  final MeditationSession session;
  final VoidCallback onTap;

  const HistoryItem({
    super.key,
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(session.formattedTime),
      title: Text('${session.formattedDuration} - ${session.type}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getMoodIcon(session.mood),
            color: _getMoodColor(session.mood),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'happy':
        return Icons.sentiment_satisfied;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'happy':
        return Colors.green;
      case 'sad':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 