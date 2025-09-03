## MindTuner Rating Flow - User Guide

### Overview

MindTuner provides a complete rating experience:
1. Meditation content generation
2. User rating and comments
3. Thank-you page
4. Rating history
5. Re-rate existing entries

### Getting Started

1) Start Backend
```bash
# Windows
run_server.bat

# Or start manually
python start_server.py
```
Backend runs at `http://localhost:8080`.

2) Start Frontend
```bash
cd MindTuner/frontend
flutter run
```

### Using the Rating Flow

1) Enter the rating screen
- Use the rating test entry on the home screen or navigation

2) View generated content
- See title, description, mood tag, etc.

3) Submit a rating
- Choose 1–5 stars
- Optionally add a comment
- Tap “Submit Rating”

4) Thank-you page
- Confirms submission and shows details
- Actions: “Rate Again” or “View History”

5) Rating history
- See all past ratings sorted by time
- Add new rating or re-rate any record

### Features

- Thank-you page with clear confirmation and options
- Full rating history with sorting
- Re-rate any record to update your feedback

### Technical Notes

Frontend components
- `MarkWidget`: rating widget and thank-you display
- `TestRatingScreen`: rating test screen
- `RatingHistoryScreen`: rating history

Backend APIs
- `POST /rating/` – create rating
- `GET /rating/user/{user_id}` – user rating history
- `GET /rating/{rating_id}` – get rating by id
- `PUT /rating/{rating_id}` – update rating
- `DELETE /rating/{rating_id}` – delete rating

Data model
- `RatingRecord` with type enum (meditation, mood, general)

### Troubleshooting

1) Backend connection
- Ensure server is running
- Check port 8080 availability
- Verify Firebase configuration

2) Rating submission fails
- Check network
- Ensure a star value is selected
- Inspect console logs

3) History not shown
- Confirm user ID
- Check backend database connection
- Try refreshing

### Development Notes

Add new rating type
1. Extend `RatingType` enum
2. Update `_getRatingTypeText` and `_getRatingTypeColor`
3. Add backend logic

Customize thank-you page
1. Edit `_buildThankYouPage`
2. Adjust styles and layout
3. Add interactions as needed

Extend rating feature
1. Add tags
2. Implement analytics
3. Build recommendation system

### Summary

MindTuner’s rating flow is designed to be simple and complete, enabling users to provide feedback and track history, while the system learns preferences over time.


