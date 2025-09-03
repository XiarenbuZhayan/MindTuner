from typing import Optional, Dict, Any, List
from datetime import datetime, timezone
from config.config import db
from models.meditation_model import MeditationRecord, MeditationHistoryItem

import uuid

class MeditationDatabaseService:
    def __init__(self):
        self.db = db
        self.meditation_collection = "meditations"
        self.history_collection = "meditation_history"

    def save_meditation_record(
        self,
        user_id: str,
        mood: str,
        context: str,
        script: str,
        is_regenerated: bool = False,
        previous_record_id: Optional[str] = None,
        previous_script: Optional[str] = None,
        feedback: Optional[str] = None,
        score: Optional[int] = None,
        audio_url: Optional[str] = None,
        feedback_optimized: bool = False,
    ) -> Dict[str, Any]:
        record_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc)

        rec = MeditationRecord(
            record_id=record_id,
            user_id=user_id,
            mood=mood,
            context=context,
            script=script,
            is_regenerated=is_regenerated,
            previous_record_id=previous_record_id,
            previous_script=previous_script,
            feedback=feedback,
            audio_url=audio_url,
            feedback_optimized=feedback_optimized,
            created_at=now,
            updated_at=now,
        )
        self.db.collection(self.meditation_collection).document(record_id).set(rec.dict())

        hist = MeditationHistoryItem(
            record_id=record_id,
            user_id=user_id,
            mood=mood,
            context=context,
            script=script,
            is_regenerated=is_regenerated,
            score=score,
            audio_url=audio_url,
            feedback_optimized=feedback_optimized,
            created_at=now,
            updated_at=now,
        )
        self.db.collection(self.history_collection).document(record_id).set(hist.dict())

        return {
            "record_id": record_id,
            "script": script,
            "created_at": now,
            "is_regenerated": is_regenerated,
        }

    def get_user_meditation_history(self, user_id: str, limit: int = 50) -> List[Dict[str, Any]]:
        """获取用户的冥想历史记录"""
        try:
            # 从历史记录集合中查询
            query = self.db.collection(self.history_collection).where("user_id", "==", user_id)
            query = query.order_by("created_at", direction="DESCENDING").limit(limit)
            
            docs = query.stream()
            records = []
            
            for doc in docs:
                data = doc.to_dict()
                # 确保created_at是datetime对象
                if isinstance(data.get("created_at"), str):
                    data["created_at"] = datetime.fromisoformat(data["created_at"].replace("Z", "+00:00"))
                
                # 确保记录包含所有必要字段
                formatted_record = {
                    "record_id": data.get("record_id", ""),
                    "user_id": data.get("user_id", ""),
                    "mood": data.get("mood", ""),
                    "context": data.get("context", ""),
                    "script": data.get("script", ""),
                    "created_at": data.get("created_at"),
                    "updated_at": data.get("updated_at"),
                    "is_regenerated": data.get("is_regenerated", False),
                    "score": data.get("score"),
                    "feedback": data.get("feedback"),
                    "audio_url": data.get("audio_url"),
                }
                records.append(formatted_record)
            
            return records
        except Exception as e:
            print(f"Error getting meditation history: {e}")
            return []

    def get_meditation_record(self, record_id: str) -> Optional[Dict[str, Any]]:
        """根据记录ID获取单个冥想记录"""
        try:
            doc = self.db.collection(self.history_collection).document(record_id).get()
            if doc.exists:
                data = doc.to_dict()
                # 确保created_at是datetime对象
                if isinstance(data.get("created_at"), str):
                    data["created_at"] = datetime.fromisoformat(data["created_at"].replace("Z", "+00:00"))
                
                # 确保记录包含所有必要字段
                formatted_record = {
                    "record_id": data.get("record_id", ""),
                    "user_id": data.get("user_id", ""),
                    "mood": data.get("mood", ""),
                    "context": data.get("context", ""),
                    "script": data.get("script", ""),
                    "created_at": data.get("created_at"),
                    "updated_at": data.get("updated_at"),
                    "is_regenerated": data.get("is_regenerated", False),
                    "score": data.get("score"),
                    "feedback": data.get("feedback"),
                    "audio_url": data.get("audio_url"),
                }
                return formatted_record
            return None
        except Exception as e:
            print(f"Error getting meditation record: {e}")
            return None

    def update_meditation_record(self, record_id: str, score: int, feedback: Optional[str] = None) -> bool:
        """更新冥想记录的评价和反馈"""
        try:
            update_data = {
                "score": score,
                "updated_at": datetime.now(timezone.utc)
            }
            if feedback:
                update_data["feedback"] = feedback
            
            self.db.collection(self.history_collection).document(record_id).update(update_data)
            return True
        except Exception as e:
            print(f"Error updating meditation record: {e}")
            return False

    def delete_meditation_record(self, record_id: str) -> bool:
        """删除冥想记录"""
        try:
            # 同时删除meditations和meditation_history中的记录
            self.db.collection(self.meditation_collection).document(record_id).delete()
            self.db.collection(self.history_collection).document(record_id).delete()
            return True
        except Exception as e:
            print(f"Error deleting meditation record: {e}")
            return False

    def get_meditation_history_by_date(self, user_id: str, limit: int = 50) -> Dict[str, List[Dict[str, Any]]]:
        """按日期分组获取用户的冥想历史记录"""
        try:
            # 获取原始记录
            records = self.get_user_meditation_history(user_id, limit)
            grouped_records = {}
            
            for record in records:
                # 确保 created_at 是 datetime 对象
                created_at = record.get("created_at")
                if isinstance(created_at, str):
                    created_at = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
                
                # 格式化日期为 YYYY-MM-DD 格式
                date_str = created_at.strftime("%Y-%m-%d")
                if date_str not in grouped_records:
                    grouped_records[date_str] = []
                
                # 确保记录包含所有必要字段
                formatted_record = {
                    "record_id": record.get("record_id", ""),
                    "user_id": record.get("user_id", ""),
                    "mood": record.get("mood", ""),
                    "context": record.get("context", ""),
                    "script": record.get("script", ""),
                    "created_at": created_at.isoformat(),
                    "updated_at": record.get("updated_at", ""),
                    "is_regenerated": record.get("is_regenerated", False),
                    "score": record.get("score"),
                    "feedback": record.get("feedback"),
                    "audio_url": record.get("audio_url"),
                }
                grouped_records[date_str].append(formatted_record)
            
            return grouped_records
        except Exception as e:
            print(f"Error getting meditation history by date: {e}")
            return {}
