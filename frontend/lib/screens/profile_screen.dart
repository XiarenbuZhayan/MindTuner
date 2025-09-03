import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatelessWidget {
  final bool isLoggedIn;
  final String? userId;
  final String? userEmail;
  final String? userDisplayName;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  
  const ProfileScreen({
    super.key,
    required this.isLoggedIn,
    this.userId,
    this.userEmail,
    this.userDisplayName,
    required this.onLogin,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoggedIn ? _buildLoggedInView() : _buildNotLoggedInView(),
    );
  }

  Widget _buildLoggedInView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryBlue,
            child: Icon(Icons.person, size: 40, color: AppColors.white),
          ),
          const SizedBox(height: 16),
                     Text(
             userDisplayName ?? 'User',
             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
           ),
          const SizedBox(height: 8),
          Text(
            userEmail ?? '',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
                     Text(
             'User ID: $userId',
             style: const TextStyle(color: Colors.grey, fontSize: 12),
           ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
            child: ElevatedButton(
              onPressed: onLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: AppColors.white,
              ),
                             child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 40,
            child: Icon(Icons.person, size: 40),
          ),
          const SizedBox(height: 16),
                     const Text(
             'Not Logged In',
             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
           ),
          const SizedBox(height: 8),
                     const Text(
             'Login to sync your meditation data',
             style: TextStyle(color: Colors.grey),
           ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
            child: ElevatedButton(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
              ),
                             child: const Text('Login'),
            ),
          ),
        ],
      ),
    );
  }
} 