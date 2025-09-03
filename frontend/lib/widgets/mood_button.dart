import 'package:flutter/material.dart';
import '../utils/constants.dart';

class MoodButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String mood;
  final String selectedMood;
  final Function(String) onTap;

  const MoodButton({
    super.key,
    required this.label,
    required this.icon,
    required this.mood,
    required this.selectedMood,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedMood == mood;
    
    return GestureDetector(
      onTap: () => onTap(mood),
      child: Column(
        children: [
          Container(
            width: AppSizes.moodButtonSize,
            height: AppSizes.moodButtonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primaryBlue : Colors.grey.shade200,
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.white : Colors.grey,
              size: AppSizes.iconSize,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primaryBlue : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
} 