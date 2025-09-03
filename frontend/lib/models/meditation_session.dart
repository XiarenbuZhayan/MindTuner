
// 旧版本
class MeditationSession {
  final String id;
  final DateTime date;
  final Duration duration;
  final String mood;
  final String type;
  final String? notes;
  final int? rating;
  final String? review;

  MeditationSession({
    required this.id,
    required this.date,
    required this.duration,
    required this.mood,
    required this.type,
    this.notes,
    this.rating,
    this.review,
  });

  factory MeditationSession.fromJson(Map<String, dynamic> json) {
    return MeditationSession(
      id: json['id'],
      date: DateTime.parse(json['date']),
      duration: Duration(minutes: json['durationMinutes']),
      mood: json['mood'],
      type: json['type'],
      notes: json['notes'],
      rating: json['rating'],
      review: json['review'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'durationMinutes': duration.inMinutes,
      'mood': mood,
      'type': type,
      'notes': notes,
      'rating': rating,
      'review': review,
    };
  }

  String get formattedDate {
    return '${date.month}月${date.day}日';
  }

  String get formattedTime {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDuration {
    final minutes = duration.inMinutes;
    return '$minutes分钟';
  }
} 