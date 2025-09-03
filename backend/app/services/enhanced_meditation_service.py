import json
import time
import uuid
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from datetime import datetime
import requests
from config.config import DEEPSEEK_API_KEY

from services.feedback_analysis_service import (
    FeedbackAnalysisService, 
    UserFeedback, 
    FeedbackAnalysis
)
from services.database_service import MeditationDatabaseService

@dataclass
class EnhancedMeditationRequest:
    """Enhanced Meditation Request"""
    user_id: str
    mood: str
    description: str
    feedback_analysis: Optional[FeedbackAnalysis] = None

class EnhancedMeditationService:
    """Enhanced Meditation Generation Service, supports content optimization based on user feedback"""

    def __init__(self, deepseek_api_key: str):
        self.api_key = deepseek_api_key
        self.base_url = "https://api.deepseek.com"
        self.headers = {
            "Authorization": f"Bearer {deepseek_api_key}",
            "Content-Type": "application/json"
        }
        self.feedback_analysis_service = FeedbackAnalysisService(deepseek_api_key)
        self.db_service = MeditationDatabaseService()
    
    async def generate_enhanced_meditation(self, request: EnhancedMeditationRequest) -> Dict[str, Any]:
        """Generate enhanced meditation content based on user feedback"""
        self.feedback_analysis_service.analyze_feedback(request.feedback_analysis)
        try:
            # Get user feedback history
            user_feedbacks = self._get_user_feedback_history(request.user_id)
            
            # Build enhanced prompt
            enhanced_prompt = self._build_enhanced_prompt(request, user_feedbacks)
            
            # Generate meditation content
            result = await self._generate_meditation_content(enhanced_prompt, request)
            
            if not result["success"]:
                return result
            
            # Generate audio
            audio_url = None
            try:
                from services.tts_service import TTSService
                tts_service = TTSService()
                audio_url = tts_service.generate_and_store_speech(
                    result["script"], 
                    str(uuid.uuid4())
                )
            except Exception as e:
                print(f"TTS generation failed: {e}")
                audio_url = None
            
            # Save meditation record
            saved = self.db_service.save_meditation_record(
                user_id=request.user_id,
                mood=request.mood,
                context=request.description,
                script=result["script"],
                audio_url=audio_url,
                feedback_optimized=True
            )
            
            return {
                "status": "success",
                "record_id": saved["record_id"],
                "meditation_script": result["script"],
                "audio_url": audio_url,
                "metadata": {
                    **result["metadata"],
                    "feedback_optimized": True,
                    "user_feedback_count": len(user_feedbacks)
                }
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": f"Failed to generate enhanced meditation: {str(e)}"
            }
    
    def _get_user_feedback_history(self, user_id: str) -> List[UserFeedback]:
        """Get user feedback history"""
        try:
            from services.rating_service import RatingService
            rating_service = RatingService()
            
            ratings = rating_service.get_user_ratings(user_id=user_id, limit=20)
            
            feedbacks = []
            for rating in ratings:
                meditation_record = self.db_service.get_meditation_by_id(rating.get('meditation_id', ''))
                
                if meditation_record:
                    feedback = UserFeedback(
                        user_id=rating['user_id'],
                        rating_score=rating['score'],
                        rating_comment=rating.get('comment'),
                        meditation_id=rating.get('meditation_id', ''),
                        mood=meditation_record.get('mood', ''),
                        context=meditation_record.get('context', ''),
                        created_at=datetime.fromisoformat(rating['created_at'])
                    )
                    feedbacks.append(feedback)
            
            return feedbacks
            
        except Exception as e:
            print(f"Failed to get user feedback history: {e}")
            return []
    
    def _build_enhanced_prompt(self, request: EnhancedMeditationRequest, 
                             user_feedbacks: List[UserFeedback]) -> str:
        """Build enhanced prompt, including user feedback analysis"""
        
        feedback_analysis = None
        if user_feedbacks:
            latest_feedback = user_feedbacks[0]
            feedback_analysis = self.feedback_analysis_service.analyze_user_feedback(
                latest_feedback, user_feedbacks[1:]
            )
        
        feedback_summary = ""
        if feedback_analysis:
            feedback_summary = f"""
User Feedback Analysis:
- Overall Satisfaction: {feedback_analysis.overall_satisfaction:.2f}
- Key Issues: {', '.join(feedback_analysis.key_issues) if feedback_analysis.key_issues else 'None'}
- Improvement Suggestions: {', '.join(feedback_analysis.improvement_suggestions) if feedback_analysis.improvement_suggestions else 'None'}
- User Preferences: {json.dumps(feedback_analysis.user_preferences, ensure_ascii=False)}
- Optimization Guidance: {feedback_analysis.next_meditation_guidance}
"""
        
        history_summary = ""
        if user_feedbacks:
            recent_feedbacks = user_feedbacks[:5]
            history_summary = "\nUser Feedback History:\n"
            for i, feedback in enumerate(recent_feedbacks, 1):
                history_summary += f"{i}. Rating: {feedback.rating_score}/5 stars"
                if feedback.rating_comment:
                    history_summary += f", Comment: {feedback.rating_comment}"
                history_summary += f", Mood: {feedback.mood}\n"

        enhanced_prompt = f"""You are a professional meditation guide, and you need to generate personalized meditation content for a user.

User Current State:
- Mood: {request.mood}
- Description: {request.description}
- User ID: {request.user_id}

{feedback_summary}
{history_summary}

based on the above information, please generate a highly personalized meditation script with the following requirements:

1. Content Personalization:
   - Adjust the content style based on the user's historical feedback and preferences
   - Provide precise guidance tailored to the user's specific mood and description
   - Avoid issues mentioned in the user's previous feedback

2. Style Optimization:
   - Adjust the guidance tone based on user preferences
   - Optimize content structure and rhythm
   - Enhance practicality and operability

3. Specific Requirements:
   - Duration: 2-3 minutes
   - Language: Gentle, supportive tone
   - Structure: Introduction → Main Practice → Conclusion
   - Personalization: Directly address the user's current state
   - Practicality: Provide specific relaxation and adjustment techniques

4. Special Attention:
   - If user satisfaction is low, focus on improving content quality and personalization
   - If user satisfaction is high, maintain strengths and fine-tune optimizations
   - Adjust based on specific feedback in user comments

Please generate a complete meditation script, starting directly with the guidance text, without any titles or explanatory text."""

        return enhanced_prompt
    
    async def _generate_meditation_content(self, prompt: str, 
                                         request: EnhancedMeditationRequest) -> Dict[str, Any]:
        """Generate meditation content"""

        try:
            payload = {
                "model": "deepseek-chat",
                "messages": [
                    {
                        "role": "system",
                        "content": "You are a professional meditation guide, and you need to generate personalized meditation content for a user."
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                "temperature": 0.7,
                "max_tokens": 800,
                "top_p": 0.9,
                "frequency_penalty": 0.2,
                "presence_penalty": 0.1,
                "stream": False
            }
            
            response = requests.post(
                f"{self.base_url}/v1/chat/completions",
                headers=self.headers,
                json=payload,
                timeout=30
            )
            
            if response.status_code != 200:
                return {
                    "success": False,
                    "error": f"API request failed: {response.status_code}",
                    "details": response.text
                }
            
            result = response.json()
            
            if "choices" not in result or len(result["choices"]) == 0:
                return {
                    "success": False,
                    "error": "Invalid API response format",
                    "details": result
                }
            
            script_content = result["choices"][0]["message"]["content"]
            processed_script = self._post_process_script(script_content, request)
            
            return {
                "success": True,
                "script": processed_script,
                "metadata": {
                    "mood": request.mood,
                    "description": request.description,
                    "estimated_duration": "2-3分钟",
                    "generated_at": time.time(),
                    "feedback_optimized": True,
                    "token_usage": result.get("usage", {})
                }
            }
            
        except requests.exceptions.Timeout:
            return {
                "success": False,
                "error": "API request timed out",
                "details": "Request exceeded 30 seconds"
            }
        except requests.exceptions.RequestException as e:
            return {
                "success": False,
                "error": "Network request error",
                "details": str(e)
            }
        except json.JSONDecodeError as e:
            return {
                "success": False,
                "error": "JSON parsing error",
                "details": str(e)
            }
        except Exception as e:
            return {
                "success": False,
                "error": "Unknown error",
                "details": str(e)
            }
    
    def _post_process_script(self, script: str, request: EnhancedMeditationRequest) -> str:
        """Post-process meditation script"""
        
        processed = script.strip()
        
        # Ensure appropriate opening
        if not any(start_word in processed[:100].lower() for start_word in 
                  ["welcome", "hello", "let's", "take", "find", "begin", "start"]):
            processed = f"Let us begin this meditation journey. {processed}"
        
        # Ensure gentle ending
        if not any(end_word in processed[-150:].lower() for end_word in 
                  ["gently", "slowly", "when you're ready", "take your time", "gradually"]):
            processed += "\n\nWhen you're ready, slowly open your eyes and bring this calm back to your daily life."
        
        return processed

# 创建全局实例
enhanced_meditation_service = EnhancedMeditationService(DEEPSEEK_API_KEY)

