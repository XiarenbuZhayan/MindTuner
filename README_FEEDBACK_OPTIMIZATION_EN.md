## Feedback Optimization - User Guide

### Overview

MindTuner refines meditation content based on your ratings and comments, so you can observe how AI improves guidance quality across sessions.

### How to Observe Improvements

1) Open the Enhanced Meditation screen (✨ icon)
- The page shows your feedback analysis

2) Review Analysis Panels
- Satisfaction percentage
- Latest rating and comment
- Detected issues by AI
- Optimization suggestions
- User preferences (style, tone, duration)

3) Generate Optimized Content
- Enter mood and detailed description
- Click “Generate feedback-optimized meditation”
- Check whether issues you reported are fixed

4) Rate and Comment
- Give 1–5 stars and write a comment
- The AI uses your feedback to improve next time

### Example Improvement Path

- First use: baseline template, 3 stars, “tone is a bit fast”
- Second use: AI slows tone, 4 stars, “much better”
- Third use: more personalized content, 5 stars, “perfect”

### What to Watch

- Style changes (tone, pacing, length)
- Whether previous issues are resolved
- Increased personalization and preference alignment
- Satisfaction trend going up

### Testing Tips

1) Consecutive sessions (3–5 times)
- Provide ratings and detailed comments each time
- Observe improvement trajectory

2) Different moods and scenarios
- See if AI adapts appropriately

3) Detailed feedback
- Provide concrete likes/dislikes and suggestions

### Technical Principles (High Level)

1) Feedback analysis
- Uses rating history and comments to infer preferences and issues

2) Content optimization
- Adjusts generation strategy based on analysis
- Avoids known issues, emphasizes preferred elements

3) Continual learning
- Each rating updates the user model and refines future content

### Troubleshooting

1) No improvement visible
- Ensure sufficient history (2–3+ ratings)
- Provide clear, concrete comments

2) Empty analysis
- Confirm the user has rating records
- Check network and retry

3) Generation failures
- Ensure backend is running
- Verify DeepSeek API configuration
- Check logs for details

### Best Practices

- Provide specific comments, not just stars
- Keep test inputs consistent for comparison
- Be patient; improvements compound across sessions

### Summary

MindTuner shows clearly how feedback shapes meditations over time. Your ratings and comments help the AI align content to your preferences, boosting quality session by session.


