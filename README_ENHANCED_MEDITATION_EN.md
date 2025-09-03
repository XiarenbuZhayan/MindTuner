## Intelligent Meditation Generation - User Guide

### Overview

MindTuner's Intelligent Meditation Generation is a core feature that personalizes guided meditations based on user ratings and feedback. It leverages DeepSeek AI's memory capability to progressively optimize future sessions.

### Key Features

1) Smart Feedback Analysis
- Satisfaction score calculation based on history
- Problem detection from comments
- Preference analysis (style, tone, pacing, duration)
- Actionable optimization suggestions

2) Feedback-Driven Content Optimization
- Personalized adjustments by preferences
- Avoids previously reported issues
- Matches preferred guidance style and duration
- Continuous improvement after every rating

3) Visual Feedback Panels
- Analysis cards for satisfaction, issues, suggestions
- Feedback history
- Optimized-content indicators

### How to Use

1) Start Backend
```bash
cd MindTuner/backend
python main.py
```

2) Start Frontend
```bash
cd MindTuner/frontend
flutter run
```

3) Generate Enhanced Meditation
- Open the enhanced generation screen (✨ icon on the home screen)
- Review feedback analysis and history
- Enter mood and description, then generate
- Rate and comment after listening; future content will improve

### Architecture

Backend Components
- `feedback_analysis_service.py`
  - `analyze_user_feedback(feedback, previous_feedbacks) -> FeedbackAnalysis`
  - `_calculate_satisfaction(...) -> float`
  - `_analyze_feedback_content(...) -> Dict`

- `enhanced_meditation_service.py`
  - `generate_enhanced_meditation(request) -> Dict`
  - `_get_user_feedback_history(user_id) -> List[UserFeedback]`
  - `_build_enhanced_prompt(request, user_feedbacks) -> str`

- Routes (`enhanced_meditation.py`)
  - `POST /enhanced-meditation/generate-enhanced-meditation`
  - `GET /enhanced-meditation/user/{user_id}/feedback-analysis`
  - `GET /enhanced-meditation/user/{user_id}/feedback-history`

Frontend Components
- `enhanced_meditation_api.dart`: API methods for generate, analysis, history
- `enhanced_meditation_screen.dart`: UI for analysis, form, content, rating

### Testing

Run script:
```bash
cd MindTuner/backend
python test_enhanced_meditation.py
```

Validates:
1. Create mock rating data
2. Get feedback analysis
3. Get feedback history
4. Generate enhanced meditation
5. Verify analysis quality

### Requirements

Environment variables
```bash
DEEPSEEK_API_KEY=your_deepseek_api_key
```

Python dependencies
```bash
pip install fastapi uvicorn firebase-admin requests
```

Flutter dependencies (excerpt)
```yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.2
```

### Troubleshooting

1) API request failure
- Check `DEEPSEEK_API_KEY`
- Verify network
- Inspect backend logs

2) Empty analysis
- Ensure the user has rating history
- Check database connectivity
- Validate rating data format

3) Low content quality
- Check DeepSeek API response
- Verify prompt template
- Ensure feedback data completeness

### Future Work

- Multimodal feedback (voice, expressions)
- Group-level optimization
- A/B testing for strategies
- Personalized recommendations
- Caching, batching, async generation

### Summary

By analyzing ratings and comments, MindTuner tailors each session to the user. With continuous feedback, the model learns preferences and steadily improves guidance quality.


