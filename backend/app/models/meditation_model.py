from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class MeditationRecord(BaseModel):
    record_id: str
    user_id: str
    mood: str
    context: str
    script: str
    is_regenerated: bool = False
    previous_record_id: Optional[str] = None
    previous_script: Optional[str] = None
    feedback: Optional[str] = None
    score: Optional[int] = Field(default=None, ge=1, le=5)
    audio_url: Optional[str] = None
    feedback_optimized: bool = False
    created_at: datetime
    updated_at: datetime

class MeditationHistoryItem(BaseModel):
    record_id: str
    user_id: str
    mood: str
    context: str
    script: str
    is_regenerated: bool = False
    score: Optional[int] = Field(default=None, ge=1, le=5)
    audio_url: Optional[str] = None
    feedback_optimized: bool = False
    created_at: datetime
    updated_at: datetime