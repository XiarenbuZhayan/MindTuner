import 'package:flutter/material.dart';
import 'screens/meditation_screens.dart';

// meditation type selection page
class MeditationTypeScreen extends StatelessWidget {
  const MeditationTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Meditation Type'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMeditationCard(
            context,
            'Relax after work',
            'Relaxation meditation for after work',
            Icons.work,
            Colors.blue,
          ),
          _buildMeditationCard(
            context,
            'High-stress task',
            'Meditation to help with high-stress tasks',
            Icons.trending_up,
            Colors.orange,
          ),
          _buildMeditationCard(
            context,
            'Sleep Meditation',
            'Relaxation meditation to help you sleep',
            Icons.bedtime,
            Colors.purple,
          ),
          _buildMeditationCard(
            context,
            'Focus Training',
            'Meditation to improve focus and concentration',
            Icons.psychology,
            Colors.green,
          ),
          _buildMeditationCard(
            context,
            'Emotion Management',
            'Meditation to help manage emotions',
            Icons.favorite,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildMeditationCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // navigate to meditation progress page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MeditationPlayScreen(meditationScript: '', recordId: '', mood: ''),
            ),
          );
        },
      ),
    );
  }
}

// settings page
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  String _selectedLanguage = 'Chinese';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Push Notifications'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('Sound Effects'),
            trailing: Switch(
              value: _soundEnabled,
              onChanged: (value) {
                setState(() {
                  _soundEnabled = value;
                });
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(_selectedLanguage),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showLanguageDialog();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About App'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showAboutDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Feedback'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Chinese'),
              onTap: () {
                setState(() {
                  _selectedLanguage = 'Chinese';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              onTap: () {
                setState(() {
                  _selectedLanguage = 'English';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Mind Tuner'),
        content: const Text(
          'Mind Tuner is an app that helps users meditate.\n\nVersion: 1.0.0\nDeveloper: Mind Tuner Team',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Feedback'),
        content: const Text(
          'If you encounter any issues, please contact us through the following methods:\n\n'
          'Email: support@mindtuner.com\n'
          'Phone: 400-123-4567',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// statistics page
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard('Meditation Time This Week', '12 hours 30 minutes', Icons.timer, Colors.blue),
            const SizedBox(height: 16),
            _buildStatCard('Consecutive Meditation Days', '7 days', Icons.calendar_today, Colors.green),
            const SizedBox(height: 16),
            _buildStatCard('Total Meditation Count', '45 times', Icons.psychology, Colors.orange),
            const SizedBox(height: 16),
            _buildStatCard('Average Meditation Duration', '15 minutes', Icons.analytics, Colors.purple),
            const SizedBox(height: 32),
            const Text(
              'Mood Trend This Week',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMoodChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'Mood Trend Chart\n\nHere you can see the trend of your mood this week',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
} 