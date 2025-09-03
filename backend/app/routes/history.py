from datetime import datetime
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, Dict, List

from services.database_service import MeditationDatabaseService


hist = APIRouter()
db_service = MeditationDatabaseService()

# Meditation records
class records(BaseModel):
    hist_id: str
    user_id: str
    mood: str
    time: datetime

    score: Optional[int] = None
    feedback: Optional[str] = None

# create new records
class create_records(BaseModel):
    user_id: str
    mood: str


class feedback_update(BaseModel):
    score: int = Field(..., ge=1, le=5)
    feedback: Optional[str] = None


class MeditationHistoryResponse(BaseModel):
    record_id:str
    mood:str
    context:str
    script:str
    created_at:datetime
    is_regenerated:bool
    score: Optional[int] = None
    feedback: Optional[str] = None


# get user meditation history
@hist.get("/{user_id}", response_model=list[MeditationHistoryResponse])
def get_user_meditation_history(user_id:str, limit:int = 50):
    try:
        records = db_service.get_user_meditation_history(user_id, limit)
        if not records:
            return []  # 返回空列表而不是404，因为用户可能确实没有记录
        return [MeditationHistoryResponse(**record) for record in records]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# get user meditation history grouped by date
@hist.get("/{user_id}/grouped")
def get_user_meditation_history_grouped(user_id:str, limit:int = 50):
    try:
        grouped_records = db_service.get_meditation_history_by_date(user_id, limit)
        if not grouped_records:
            return {}  # 返回空字典而不是404，因为用户可能确实没有记录
        return grouped_records
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# get meditation record by record id
@hist.get("/record/{record_id}", response_model=MeditationHistoryResponse)
def get_meditation_record(record_id:str):
    try:
        record = db_service.get_meditation_record(record_id)
        if record is None:
            raise HTTPException(status_code=404, detail="Record not found")
        return MeditationHistoryResponse(**record)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# update feedback
@hist.put("/record/{record_id}/feedback")
def update_feedback(record_id:str, score:int, feedback:str = None):
    try:
        if not 1 <= score <= 5:
            raise HTTPException(status_code=400, detail="Score must be between 1 and 5")
        
        success = db_service.update_meditation_record(record_id, score, feedback)
        if success:
            return {"message": "Feedback updated successfully"}
        else:
            raise HTTPException(status_code=500, detail="Failed to update feedback")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@hist.delete("/record/{record_id}")
def delete_meditation_record(record_id:str):
    try:
        success = db_service.delete_meditation_record(record_id)
        if success:
            return {"message": "Record deleted successfully"}
        else:
            raise HTTPException(status_code=500, detail="Failed to delete record")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@hist.get("/test-database")
def test_database_connection():
    """测试数据库连接"""
    try:
        # 尝试执行一个简单的查询来测试连接
        test_records = db_service.get_user_meditation_history("test-user", limit=1)
        return {
            "success": True,
            "message": "数据库连接正常",
            "timestamp": datetime.now().isoformat(),
            "test_records_count": len(test_records)
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }




