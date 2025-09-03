import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/audio_service.dart';
import '../services/reminder_service.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'auth/login_screen.dart';
import 'meditation_reminder_screen.dart';
import 'rating_history_detail_screen.dart';
import 'rating_history_screen.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  
  // User state management
  bool _isLoggedIn = false;
  String _userId = 'test-user';
  String _userEmail = '';
  String _userDisplayName = '';
  
  // Reminder state management
  bool _isReminderEnabled = false;
  String _reminderTime = '08:00';
  List<bool> _reminderDays = [true, true, true, true, true, false, false];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadReminderStatus();
  }

  // Check login status
    void _checkLoginStatus() {
      // Here you can check local storage or Firebase Auth status
      // Using simple logic for now
      setState(() {
        _isLoggedIn = _userId != 'test-user';
      });
    }

  // Update user information
  void _updateUserInfo(String userId, String userEmail, String userDisplayName) {
    setState(() {
      _userId = userId;
      _userEmail = userEmail;
      _userDisplayName = userDisplayName;
      _isLoggedIn = true;
    });
  }

  // Clear user information
  void _clearUserInfo() {
    setState(() {
      _userId = 'test-user';
      _userEmail = '';
      _userDisplayName = '';
      _isLoggedIn = false;
    });
  }

  // Load reminder status
  Future<void> _loadReminderStatus() async {
    try {
      final settings = await ReminderService.loadReminderSettings();
      setState(() {
        _isReminderEnabled = settings['isEnabled'] ?? false;
        _reminderTime = settings['time'] ?? '08:00';
        _reminderDays = List<bool>.from(settings['days'] ?? [true, true, true, true, true, false, false]);
      });
    } catch (e) {
      print('加载提醒状态失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MindTuner', style: AppStyles.titleStyle),
        actions: [
          // Meditation reminder settings button
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  _isReminderEnabled ? Icons.notifications_active : Icons.notifications,
                  color: _isReminderEnabled ? Colors.green : Colors.grey,
                ),
                tooltip: _isReminderEnabled 
                            ? 'Meditation reminder enabled (${ReminderService.getSelectedDaysDescription(_reminderDays)})'
        : 'Meditation Reminder Settings',
                onPressed: _openMeditationReminder,
              ),
              if (_isReminderEnabled)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),

          // Rating history details button
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Rating History Details',
            onPressed: _openRatingHistoryDetail,
          ),

          // // Rating history button
          // IconButton(
          //   icon: const Icon(Icons.history),
          //   tooltip: 'Rating History',
          //   onPressed: _viewRatingHistory,
          // ),


          // User information display
          if (_isLoggedIn && _userDisplayName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Text(
                  'Welcome, $_userDisplayName',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          // Login/Logout button
          IconButton(
            icon: Icon(_isLoggedIn ? Icons.logout : Icons.login),
            tooltip: _isLoggedIn ? 'Sign out' : 'Sign in',
            onPressed: _isLoggedIn ? _logout : _showLoginDialog,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Meditation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Build body based on current index and login status
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(
          userId: _userId,
          userEmail: _userEmail,
          userDisplayName: _userDisplayName,
        );
      case 1:
        return HistoryScreen(
          userId: _userId,
          userEmail: _userEmail,
          userDisplayName: _userDisplayName,
        );
      case 2:
        return ProfileScreen(
          isLoggedIn: _isLoggedIn,
          userId: _userId,
          userEmail: _userEmail,
          userDisplayName: _userDisplayName,
          onLogin: _showLoginDialog,
          onLogout: _logout,
        );
      default:
        return const Center(child: Text('页面不存在'));
    }
  }

  // Show login dialog
  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Sign In'),
        content: const Text('Please sign in to use the full features'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToLogin();
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  // Navigate to login page
  void _navigateToLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
    
    if (result != null && result['success']) {
      // Login successful, update user information
      _updateUserInfo(
        result['uid'],
        result['email'],
        result['display_name'],
      );
      
             // Show welcome message
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('Welcome back, ${result['display_name']}!'),
           backgroundColor: Colors.green,
         ),
       );
      
      // Navigate to profile page
      setState(() {
        _currentIndex = 2; // Switch to profile page
      });
    }
  }

  // User logout
  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      _clearUserInfo();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully logged out'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  // Open meditation reminder settings
  void _openMeditationReminder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MeditationReminderScreen(),
      ),
    );
    
    // If returning from reminder settings, reload reminder status
    if (result == true) {
      _loadReminderStatus();
    }
  }



  // Open rating history details
  void _openRatingHistoryDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RatingHistoryDetailScreen(),
      ),
    );
  }

  // // Open enhanced meditation page
  // void _openEnhancedMeditation() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => EnhancedMeditationScreen(userId: _userId),
  //     ),
  //   );
  // }

  // View rating history
  void _viewRatingHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RatingHistoryScreen(userId: _userId),
      ),
    );
  }

  // // Test rating functionality
  // void _testRating() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => TestRatingScreen(userId: _userId),
  //     ),
  //   );
  // }
}
