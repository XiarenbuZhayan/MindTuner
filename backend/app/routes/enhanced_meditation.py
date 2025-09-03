import uuid
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional

from services.enhanced_meditation_service import (
    EnhancedMeditationService, 
    EnhancedMeditationRequest
)
from services.feedback_analysis_service import FeedbackAnalysisService
from config.config import DEEPSEEK_API_KEY

enhanced_meditation_router = APIRouter()
enhanced_meditation_service = EnhancedMeditationService(DEEPSEEK_API_KEY)
feedback_analysis_service = FeedbackAnalysisService(DEEPSEEK_API_KEY)

class EnhancedMeditationRequestModel(BaseModel):
    """增强冥想请求模型"""
    user_id: str
    mood: str
    description: str

class EnhancedMeditationResponse(BaseModel):
    """增强冥想响应模型"""
    status: str
    record_id: str
    meditation_script: str
    audio_url: Optional[str] = None
    metadata: dict
    feedback_optimized: bool = True

@enhanced_meditation_router.post("/generate-enhanced-meditation", response_model=EnhancedMeditationResponse)
async def generate_enhanced_meditation(request: EnhancedMeditationRequestModel):
    """生成基于用户反馈优化的冥想内容"""
    
    try:
        if not DEEPSEEK_API_KEY:
            raise HTTPException(status_code=500, detail="DEEPSEEK_API_KEY is missing")
        
        if not request.user_id.strip():
            raise HTTPException(status_code=400, detail="User ID cannot be empty")
        
        if not request.mood.strip():
            raise HTTPException(status_code=400, detail="Mood cannot be empty")
        
        if not request.description.strip():
            raise HTTPException(status_code=400, detail="Description cannot be empty")
        
        # 创建增强冥想请求
        enhanced_request = EnhancedMeditationRequest(
            user_id=request.user_id,
            mood=request.mood,
            description=request.description
        )
        
        # 生成增强冥想内容
        result = await enhanced_meditation_service.generate_enhanced_meditation(enhanced_request)
        
        if not result.get("status") == "success":
            raise HTTPException(
                status_code=502,
                detail={
                    "error": result.get("error", "生成失败"),
                    "details": result.get("details", "")
                }
            )
        
        return EnhancedMeditationResponse(
            status=result["status"],
            record_id=result["record_id"],
            meditation_script=result["meditation_script"],
            audio_url=result.get("audio_url"),
            metadata=result["metadata"],
            feedback_optimized=True
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"生成增强冥想失败: {str(e)}")

@enhanced_meditation_router.get("/user/{user_id}/feedback-analysis")
async def get_user_feedback_analysis(user_id: str):
    """获取用户反馈分析结果"""
    
    try:
        if not user_id.strip():
            raise HTTPException(status_code=400, detail="User ID cannot be empty")
        
        # 获取用户历史反馈
        user_feedbacks = enhanced_meditation_service._get_user_feedback_history(user_id)
        
        if not user_feedbacks:
            return {
                "user_id": user_id,
                "has_feedback": False,
                "message": "用户暂无反馈记录"
            }
        
        # 分析最新反馈
        latest_feedback = user_feedbacks[0]
        analysis = feedback_analysis_service.analyze_user_feedback(
            latest_feedback, user_feedbacks[1:]
        )
        
        return {
            "user_id": user_id,
            "has_feedback": True,
            "feedback_count": len(user_feedbacks),
            "latest_feedback": {
                "rating_score": latest_feedback.rating_score,
                "rating_comment": latest_feedback.rating_comment,
                "mood": latest_feedback.mood,
                "context": latest_feedback.context,
                "created_at": latest_feedback.created_at.isoformat()
            },
            "analysis": {
                "overall_satisfaction": analysis.overall_satisfaction,
                "key_issues": analysis.key_issues,
                "improvement_suggestions": analysis.improvement_suggestions,
                "user_preferences": analysis.user_preferences,
                "next_meditation_guidance": analysis.next_meditation_guidance
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取反馈分析失败: {str(e)}")

@enhanced_meditation_router.get("/user/{user_id}/feedback-history")
async def get_user_feedback_history(user_id: str, limit: int = 10):
    """获取用户反馈历史"""
    
    try:
        if not user_id.strip():
            raise HTTPException(status_code=400, detail="User ID cannot be empty")
        
        if limit < 1 or limit > 50:
            raise HTTPException(status_code=400, detail="Limit must be between 1 and 50")
        
        # 获取用户历史反馈
        user_feedbacks = enhanced_meditation_service._get_user_feedback_history(user_id)
        
        # 限制返回数量
        user_feedbacks = user_feedbacks[:limit]
        
        feedback_history = []
        for feedback in user_feedbacks:
            feedback_history.append({
                "rating_score": feedback.rating_score,
                "rating_comment": feedback.rating_comment,
                "mood": feedback.mood,
                "context": feedback.context,
                "created_at": feedback.created_at.isoformat()
            })
        
        return {
            "user_id": user_id,
            "feedback_count": len(feedback_history),
            "feedback_history": feedback_history
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取反馈历史失败: {str(e)}")
