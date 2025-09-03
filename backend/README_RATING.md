# Rating System API Documentation

## Overview

The rating system provides complete rating and feedback functionality for the MindTuner app, supporting multiple types of ratings (meditation, mood, general), and providing statistics and analysis features.

## Features

- ✅ Support for multiple rating types (meditation, mood, general)
- ✅ 1-5 star rating system
- ✅ Comment and feedback functionality
- ✅ User rating history records
- ✅ Rating statistics and analysis
- ✅ Batch operation support
- ✅ Complete CRUD operations

## API Endpoints

### Base URL
```
http://localhost:8080/rating
```

### 1. Create Rating
**POST** `/rating/`

Create a new rating record.

**Request Body:**
```json
{
  "user_id": "user123",
  "rating_type": "meditation",
  "score": 4,
  "comment": "This meditation experience was great!"
}
```

**Response:**
```json
{
  "rating_id": "uuid-string",
  "user_id": "user123",
  "rating_type": "meditation",
  "score": 4,
  "comment": "This meditation experience was great!",
  "created_at": "2024-01-01T12:00:00Z",
  "updated_at": "2024-01-01T12:00:00Z"
}
```

### 2. Get User Rating List
**GET** `/rating/user/{user_id}`

Get all rating records for a specified user.

**Query Parameters:**
- `rating_type` (optional): Rating type filter
- `limit` (optional): Limit on number of records returned (default 50, max 100)

**Example:**
```
GET /rating/user/user123?rating_type=meditation&limit=20
```

### 3. Get Specific Rating Record
**GET** `/rating/{rating_id}`

Get a specific record by rating ID.

### 4. Update Rating Record
**PUT** `/rating/{rating_id}`

Update an existing rating record.

**Request Body:**
```json
{
  "score": 5,
  "comment": "Updated comment"
}
```

### 5. Delete Rating Record
**DELETE** `/rating/{rating_id}`

Delete the specified rating record.

### 6. Get User Rating Statistics
**GET** `/rating/user/{user_id}/statistics`

Get user rating statistics.

**Query Parameters:**
- `rating_type` (optional): Rating type filter
- `days` (optional): Number of days to analyze (default 30, max 365)

**响应：**
```json
{
  "total_ratings": 10,
  "average_score": 4.2,
  "score_distribution": {
    "1": 0,
    "2": 1,
    "3": 2,
    "4": 4,
    "5": 3
  },
  "recent_ratings": [...]
}
```

### 7. Get All Rating Statistics
**GET** `/rating/statistics/all`

Get rating statistics for all users (admin function).

### 8. Batch Create Ratings
**POST** `/rating/batch`

Create multiple rating records in batch.

**Request Body:**
```json
[
  {
    "user_id": "user123",
    "rating_type": "meditation",
    "score": 4,
    "comment": "First meditation"
  },
  {
    "user_id": "user123",
    "rating_type": "mood",
    "score": 5,
    "comment": "Feeling great"
  }
]
```

### 9. Health Check
**GET** `/rating/health`

Check rating service status.

## Rating Types

The system supports the following rating types:

- `meditation`: Meditation experience rating
- `mood`: Mood record rating
- `general`: General rating

## Data Models

### RatingRecord
```python
class RatingRecord(BaseModel):
    rating_id: str
    user_id: str
    rating_type: RatingType
    score: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None
    created_at: datetime
    updated_at: datetime
```

### RatingStatistics
```python
class RatingStatistics(BaseModel):
    total_ratings: int
    average_score: float
    score_distribution: dict[int, int]
    recent_ratings: list[RatingResponse]
```

## Frontend Integration

### Flutter Component Usage Example

```dart
import '../widgets/mark.dart';

// Use rating component
MarkWidget(
  ratingType: RatingType.meditation,
  onRatingSubmitted: (rating, comment) {
    print('Rating: $rating, Comment: $comment');
    // Handle rating submission logic
  },
  onCancel: () {
    Navigator.of(context).pop();
  },
)

// Use simplified rating component
SimpleRatingWidget(
  initialRating: 3,
  starSize: 40,
  onRatingChanged: (rating) {
    print('Rating: $rating');
  },
)
```

## Testing

Run test scripts to verify API functionality:

```bash
cd MindTuner/backend
python test_rating_api.py
```

## Error Handling

API uses standard HTTP status codes:

- `200`: Success
- `400`: Request parameter error
- `404`: Resource not found
- `500`: Internal server error

Error response format:
```json
{
  "detail": "Error description"
}
```

## Deployment Instructions

1. Ensure backend service is running:
   ```bash
   cd MindTuner/backend/app
   python main.py
   ```

2. Frontend API address configuration:
   - Development environment: `http://localhost:8080`
   - Production environment: Configure appropriate server address

3. Database configuration:
   - Ensure Firebase configuration is correct
   - Rating data is stored in the `ratings` collection

## Notes

1. Rating range is limited to 1-5 stars
2. User ID needs to be obtained from authentication system
3. Timestamps use UTC time
4. Comment field is optional
5. Statistics function supports time range filtering

## Extension Features

Features that can be considered for the future:

- Rating trend analysis
- User rating comparison
- Rating recommendation system
- Rating export functionality
- Rating notification system
