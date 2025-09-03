from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum

class RatingType(str, Enum):
    meditation = "meditation"
    mood = "mood"
    general = "general"

class RatingRecord(BaseModel):
    rating_id: str
    user_id: str
    rating_type: RatingType
    score: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None
    created_at: datetime
    updated_at: datetime

class CreateRatingRequest(BaseModel):
    user_id: str
    rating_type: RatingType
    score: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None

class UpdateRatingRequest(BaseModel):
    score: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None

class RatingResponse(BaseModel):
    rating_id: str
    user_id: str
    rating_type: RatingType
    score: int
    comment: Optional[str] = None
    created_at: datetime
    updated_at: datetime

class RatingStatistics(BaseModel):
    total_ratings: int
    average_score: float
    score_distribution: dict[int, int]  # 每个分数的数量
    recent_ratings: list[RatingResponse]
