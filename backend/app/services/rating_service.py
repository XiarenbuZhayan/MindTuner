import uuid
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any

from models.rating_model import RatingRecord, RatingType, RatingStatistics
from config.config import db


class RatingService:
    """Rating service for managing user ratings and feedback optimization"""
    
    def __init__(self):
        self.db = db
        self.ratings_collection = "ratings"
        self.feedback_collection = "user_feedback"
        self.meditation_records_collection = "meditation_records"

    def create_rating(
        self, 
        user_id: str, 
        rating_type: RatingType, 
        score: int, 
        comment: Optional[str] = None,
        meditation_record_id: Optional[str] = None,
        feedback_tags: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """Create rating record and update meditation record if linked"""
        rating_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc)

        rating_record = RatingRecord(
            rating_id=rating_id,
            user_id=user_id,
            rating_type=rating_type,
            score=score,
            comment=comment,
            meditation_record_id=meditation_record_id,
            feedback_tags=feedback_tags,
            created_at=now,
            updated_at=now,
        )

        # Store rating record
        self.db.collection(self.ratings_collection).document(rating_id).set(rating_record.dict())

        # Update meditation record if linked
        if meditation_record_id:
            self._update_meditation_record_rating(meditation_record_id, score, comment, feedback_tags)

        # Store feedback for optimization
        if feedback_tags and len(feedback_tags) > 0:
            self._store_feedback_for_optimization(user_id, score, feedback_tags, comment)

        return {
            "rating_id": rating_id,
            "user_id": user_id,
            "rating_type": rating_type,
            "score": score,
            "comment": comment,
            "meditation_record_id": meditation_record_id,
            "feedback_tags": feedback_tags,
            "created_at": now,
            "updated_at": now,
        }

    def _update_meditation_record_rating(
        self, 
        record_id: str, 
        score: int, 
        comment: Optional[str] = None,
        feedback_tags: Optional[List[str]] = None
    ):
        """Update meditation record with rating information"""
        try:
            doc_ref = self.db.collection(self.meditation_records_collection).document(record_id)
            doc = doc_ref.get()
            
            if doc.exists:
                update_data = {
                    "score": score,
                    "feedback": comment,
                    "is_rated": True,
                    "rated_at": datetime.now(timezone.utc),
                    "feedback_tags": feedback_tags
                }
                doc_ref.update(update_data)
                print(f"✅ Updated meditation record {record_id} with rating")
            else:
                print(f"⚠️ Meditation record {record_id} not found")
        except Exception as e:
            print(f"❌ Failed to update meditation record: {e}")

    def _store_feedback_for_optimization(
        self, 
        user_id: str, 
        score: int, 
        feedback_tags: List[str], 
        comment: Optional[str] = None
    ):
        """Store user feedback for generation quality optimization"""
        try:
            feedback_id = str(uuid.uuid4())
            feedback_data = {
                "feedback_id": feedback_id,
                "user_id": user_id,
                "score": score,
                "feedback_tags": feedback_tags,
                "comment": comment,
                "created_at": datetime.now(timezone.utc),
                "processed": False
            }
            
            self.db.collection(self.feedback_collection).document(feedback_id).set(feedback_data)
            print(f"✅ Stored feedback for optimization: {feedback_tags}")
        except Exception as e:
            print(f"❌ Failed to store feedback: {e}")

    def get_user_ratings(
        self, 
        user_id: str, 
        rating_type: Optional[RatingType] = None,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """Get user ratings with optional filtering"""
        try:
            query = self.db.collection(self.ratings_collection).where("user_id", "==", user_id)
            
            if rating_type:
                query = query.where("rating_type", "==", rating_type.value)
            
            query = query.order_by("created_at", direction="DESCENDING").limit(limit)
            docs = query.stream()
            
            ratings = []
            for doc in docs:
                rating_data = doc.to_dict()
                rating_data["rating_id"] = doc.id
                ratings.append(rating_data)
            
            return ratings
        except Exception as e:
            print(f"❌ Failed to get user ratings: {e}")
            return []

    def get_rating_by_id(self, rating_id: str) -> Optional[Dict[str, Any]]:
        """Get rating by ID"""
        try:
            doc = self.db.collection(self.ratings_collection).document(rating_id).get()
            if doc.exists:
                rating_data = doc.to_dict()
                rating_data["rating_id"] = doc.id
                return rating_data
            return None
        except Exception as e:
            print(f"❌ Failed to get rating: {e}")
            return None

    def update_rating(
        self, 
        rating_id: str, 
        score: int, 
        comment: Optional[str] = None,
        feedback_tags: Optional[List[str]] = None
    ) -> Optional[Dict[str, Any]]:
        """Update existing rating"""
        try:
            doc_ref = self.db.collection(self.ratings_collection).document(rating_id)
            doc = doc_ref.get()
            
            if not doc.exists:
                return None
            
            update_data = {
                "score": score,
                "comment": comment,
                "feedback_tags": feedback_tags,
                "updated_at": datetime.now(timezone.utc)
            }
            
            doc_ref.update(update_data)
            
            # Get updated document
            updated_doc = doc_ref.get()
            rating_data = updated_doc.to_dict()
            rating_data["rating_id"] = updated_doc.id
            
            return rating_data
        except Exception as e:
            print(f"❌ Failed to update rating: {e}")
            return None

    def delete_rating(self, rating_id: str) -> bool:
        """Delete rating"""
        try:
            self.db.collection(self.ratings_collection).document(rating_id).delete()
            return True
        except Exception as e:
            print(f"❌ Failed to delete rating: {e}")
            return False

    def get_rating_statistics(
        self, 
        user_id: Optional[str] = None,
        rating_type: Optional[RatingType] = None
    ) -> Dict[str, Any]:
        """Get rating statistics"""
        try:
            query = self.db.collection(self.ratings_collection)
            
            if user_id:
                query = query.where("user_id", "==", user_id)
            if rating_type:
                query = query.where("rating_type", "==", rating_type.value)
            
            docs = list(query.stream())
            
            if not docs:
                return {
                    "total_ratings": 0,
                    "average_score": 0.0,
                    "score_distribution": {},
                    "recent_ratings": []
                }
            
            scores = []
            score_distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
            recent_ratings = []
            
            for doc in docs:
                data = doc.to_dict()
                scores.append(data["score"])
                score_distribution[data["score"]] += 1
                
                # Add to recent ratings (limit to 10)
                if len(recent_ratings) < 10:
                    data["rating_id"] = doc.id
                    recent_ratings.append(data)
            
            # Sort recent ratings by created_at
            recent_ratings.sort(key=lambda x: x.get("created_at", datetime.min), reverse=True)
            
            return {
                "total_ratings": len(scores),
                "average_score": sum(scores) / len(scores) if scores else 0.0,
                "score_distribution": score_distribution,
                "recent_ratings": recent_ratings[:10]
            }
        except Exception as e:
            print(f"❌ Failed to get rating statistics: {e}")
            return {
                "total_ratings": 0,
                "average_score": 0.0,
                "score_distribution": {},
                "recent_ratings": []
            }

    def get_user_feedback_preferences(self, user_id: str) -> Dict[str, Any]:
        """Get user's feedback preferences for generation optimization"""
        try:
            query = self.db.collection(self.feedback_collection).where("user_id", "==", user_id)
            docs = query.stream()
            
            feedback_tags = {}
            high_score_tags = []  # Tags from ratings >= 4
            low_score_tags = []   # Tags from ratings <= 2
            
            for doc in docs:
                data = doc.to_dict()
                score = data.get("score", 0)
                tags = data.get("feedback_tags", [])
                
                for tag in tags:
                    if tag not in feedback_tags:
                        feedback_tags[tag] = {"count": 0, "avg_score": 0, "total_score": 0}
                    
                    feedback_tags[tag]["count"] += 1
                    feedback_tags[tag]["total_score"] += score
                    feedback_tags[tag]["avg_score"] = feedback_tags[tag]["total_score"] / feedback_tags[tag]["count"]
                    
                    if score >= 4:
                        high_score_tags.append(tag)
                    elif score <= 2:
                        low_score_tags.append(tag)
            
            # Get most preferred tags (high scores)
            preferred_tags = [tag for tag, data in feedback_tags.items() if data["avg_score"] >= 4]
            
            # Get least preferred tags (low scores)
            avoided_tags = [tag for tag, data in feedback_tags.items() if data["avg_score"] <= 2]
            
            return {
                "user_id": user_id,
                "feedback_summary": feedback_tags,
                "preferred_tags": preferred_tags,
                "avoided_tags": avoided_tags,
                "recommendations": {
                    "emphasize": preferred_tags[:5],  # Top 5 preferred
                    "avoid": avoided_tags[:5]         # Top 5 to avoid
                }
            }
        except Exception as e:
            print(f"❌ Failed to get user feedback preferences: {e}")
            return {
                "user_id": user_id,
                "feedback_summary": {},
                "preferred_tags": [],
                "avoided_tags": [],
                "recommendations": {"emphasize": [], "avoid": []}
            }

    def health_check(self) -> Dict[str, str]:
        """Health check for rating service"""
        try:
            # Test database connection
            test_doc = self.db.collection("health_check").document("test")
            test_doc.set({"timestamp": datetime.now(timezone.utc)})
            test_doc.delete()
            
            return {
                "status": "healthy",
                "service": "rating_service",
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
        except Exception as e:
            return {
                "status": "unhealthy",
                "service": "rating_service", 
                "error": str(e),
                "timestamp": datetime.now(timezone.utc).isoformat()
            }