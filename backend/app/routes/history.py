from datetime import datetime
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional

from meditation import MeditationResponse

hist = APIRouter()

# Meditation records
class records(BaseModel):
    hist_id: str
    user_id: str
    mood: str
    time: datetime
    meditation: MeditationResponse
    score: Optional[int] = None
    feedback: Optional[str] = None

# create new records
class create_records(BaseModel):
    user_id: str
    mood: str
    meditation: MeditationResponse

class feedback_update(BaseModel):
    score: int = Field(..., ge=1, le=5)
    feedback: Optional[str] = None

# add records

@hist.post("/add")
def add_records(data:create_records):
    pass


# get records by date

@hist.get("/list")
def get_records_by_date(user_id:str, date:Optional[str] = None):
    pass
    """
    - date 格式为 "YYYY-MM-DD"
    - 如果为空则返回全部记录
    """

# get record

@hist.get("/{hist_id}")
def get_records(hist_id:str):
    pass


# feedback
@hist.get("/{hist_id}/feedback")
def update_feedback(hist_id:str, data:feedback_update):
    pass

