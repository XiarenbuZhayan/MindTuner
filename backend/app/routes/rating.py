from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

from services.rating_service import RatingService
from models.rating_model import (
    CreateRatingRequest,
    UpdateRatingRequest,
    RatingResponse,
    RatingStatistics,
    RatingType
)

rating_router = APIRouter()
rating_service = RatingService()

# 创建评分
@rating_router.post("/", response_model=RatingResponse)
async def create_rating(request: CreateRatingRequest):
    """创建新的评分记录"""
    try:
        result = rating_service.create_rating(
            user_id=request.user_id,
            rating_type=request.rating_type,
            score=request.score,
            comment=request.comment,
        )
        return RatingResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"创建评分失败: {str(e)}")

# 获取用户的所有评分
@rating_router.get("/user/{user_id}", response_model=List[RatingResponse])
async def get_user_ratings(
    user_id: str,
    rating_type: Optional[RatingType] = Query(None, description="评分类型过滤"),
    limit: int = Query(50, ge=1, le=100, description="返回记录数量限制")
):
    """获取用户的所有评分记录"""
    try:
        ratings = rating_service.get_user_ratings(
            user_id=user_id,
            rating_type=rating_type,
            limit=limit
        )
        return [RatingResponse(**rating) for rating in ratings]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取用户评分失败: {str(e)}")

# 获取特定评分记录
@rating_router.get("/{rating_id}", response_model=RatingResponse)
async def get_rating(rating_id: str):
    """根据ID获取评分记录"""
    try:
        rating = rating_service.get_rating_by_id(rating_id)
        if rating is None:
            raise HTTPException(status_code=404, detail="评分记录不存在")
        return RatingResponse(**rating)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取评分记录失败: {str(e)}")

# 更新评分记录
@rating_router.put("/{rating_id}", response_model=RatingResponse)
async def update_rating(rating_id: str, request: UpdateRatingRequest):
    """更新评分记录"""
    try:
        # 先检查记录是否存在
        existing_rating = rating_service.get_rating_by_id(rating_id)
        if existing_rating is None:
            raise HTTPException(status_code=404, detail="评分记录不存在")
        
        # 更新记录
        success = rating_service.update_rating(
            rating_id=rating_id,
            score=request.score,
            comment=request.comment,
        )
        
        if not success:
            raise HTTPException(status_code=500, detail="更新评分记录失败")
        
        # 返回更新后的记录
        updated_rating = rating_service.get_rating_by_id(rating_id)
        return RatingResponse(**updated_rating)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"更新评分记录失败: {str(e)}")

# 删除评分记录
@rating_router.delete("/{rating_id}")
async def delete_rating(rating_id: str):
    """删除评分记录"""
    try:
        success = rating_service.delete_rating(rating_id)
        if not success:
            raise HTTPException(status_code=500, detail="删除评分记录失败")
        return {"message": "评分记录删除成功"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"删除评分记录失败: {str(e)}")

# 获取用户评分统计
@rating_router.get("/user/{user_id}/statistics", response_model=RatingStatistics)
async def get_user_rating_statistics(
    user_id: str,
    rating_type: Optional[RatingType] = Query(None, description="评分类型过滤"),
    days: int = Query(30, ge=1, le=365, description="统计天数")
):
    """获取用户的评分统计信息"""
    try:
        statistics = rating_service.get_rating_statistics(
            user_id=user_id,
            rating_type=rating_type,
            days=days
        )
        return statistics
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取评分统计失败: {str(e)}")

# 获取所有评分统计（管理员功能）
@rating_router.get("/statistics/all", response_model=RatingStatistics)
async def get_all_ratings_statistics(
    rating_type: Optional[RatingType] = Query(None, description="评分类型过滤")
):
    """获取所有用户的评分统计信息（管理员功能）"""
    try:
        statistics = rating_service.get_all_ratings_statistics(rating_type=rating_type)
        return statistics
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取所有评分统计失败: {str(e)}")

# 获取特定类型评分的统计
@rating_router.get("/statistics/{rating_type}", response_model=RatingStatistics)
async def get_rating_type_statistics(
    rating_type: RatingType,
    days: int = Query(30, ge=1, le=365, description="统计天数")
):
    """获取特定类型评分的统计信息"""
    try:
        # 这里可以扩展为获取特定类型的所有用户统计
        # 目前返回空统计，可以根据需要实现
        return RatingStatistics(
            total_ratings=0,
            average_score=0.0,
            score_distribution={1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
            recent_ratings=[],
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取评分类型统计失败: {str(e)}")

# 批量创建评分（用于测试或批量导入）
@rating_router.post("/batch", response_model=List[RatingResponse])
async def create_batch_ratings(requests: List[CreateRatingRequest]):
    """批量创建评分记录"""
    try:
        results = []
        for request in requests:
            result = rating_service.create_rating(
                user_id=request.user_id,
                rating_type=request.rating_type,
                score=request.score,
                comment=request.comment,
            )
            results.append(RatingResponse(**result))
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"批量创建评分失败: {str(e)}")

# 健康检查端点
@rating_router.get("/health")
async def health_check():
    """评分服务健康检查"""
    return {
        "status": "healthy",
        "service": "rating",
        "timestamp": datetime.now().isoformat()
    }
