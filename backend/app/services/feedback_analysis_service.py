import json
import time
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from datetime import datetime, timedelta
import requests
from config.config import DEEPSEEK_API_KEY

@dataclass
class UserFeedback:
    """用户反馈数据结构"""
    user_id: str
    rating_score: int  # 1-5星评分
    rating_comment: Optional[str]  # 用户评论
    meditation_id: str  # 关联的冥想ID
    mood: str  # 用户当时的心情
    context: str  # 用户当时的描述
    created_at: datetime

@dataclass
class FeedbackAnalysis:
    """反馈分析结果"""
    overall_satisfaction: float  # 整体满意度 (0-1)
    key_issues: List[str]  # 主要问题
    improvement_suggestions: List[str]  # 改进建议
    user_preferences: Dict[str, Any]  # 用户偏好
    next_meditation_guidance: str  # 下次冥想的指导建议

class FeedbackAnalysisService:
    """User feedback analysis service"""
    
    def __init__(self, deepseek_api_key: str):
        self.api_key = deepseek_api_key
        self.base_url = "https://api.deepseek.com"
        self.headers = {
            "Authorization": f"Bearer {deepseek_api_key}",
            "Content-Type": "application/json"
        }
    
    def analyze_user_feedback(self, feedback: UserFeedback, 
                            previous_feedbacks: List[UserFeedback] = None) -> FeedbackAnalysis:
        """Analyze user feedback and generate optimization suggestions"""
        
        if previous_feedbacks is None:
            previous_feedbacks = []
        
        overall_satisfaction = self._calculate_satisfaction(feedback, previous_feedbacks)
        analysis_result = self._analyze_feedback_content(feedback, previous_feedbacks)
        next_meditation_guidance = self._generate_next_meditation_guidance(
            feedback, previous_feedbacks, analysis_result
        )
        
        return FeedbackAnalysis(
            overall_satisfaction=overall_satisfaction,
            key_issues=analysis_result.get('key_issues', []),
            improvement_suggestions=analysis_result.get('improvement_suggestions', []),
            user_preferences=analysis_result.get('user_preferences', {}),
            next_meditation_guidance=next_meditation_guidance
        )
    
    def _calculate_satisfaction(self, feedback: UserFeedback, 
                              previous_feedbacks: List[UserFeedback]) -> float:
        """Calculate user satisfaction"""
        current_satisfaction = feedback.rating_score / 5.0
        
        if previous_feedbacks:
            recent_cutoff = datetime.now() - timedelta(days=30)
            recent_feedbacks = [f for f in previous_feedbacks 
                              if f.created_at > recent_cutoff]
            
            if recent_feedbacks:
                recent_satisfaction = sum(f.rating_score for f in recent_feedbacks) / (len(recent_feedbacks) * 5.0)
                return current_satisfaction * 0.6 + recent_satisfaction * 0.4
        
        return current_satisfaction
    
    def _analyze_feedback_content(self, feedback: UserFeedback, 
                                previous_feedbacks: List[UserFeedback]) -> Dict[str, Any]:
        """Analyze feedback content, extract key information and preferences"""
        
        # Use DeepSeek API to analyze feedback content
        analysis_prompt = self._build_analysis_prompt(feedback, previous_feedbacks)
        
        try:
            result = self._call_deepseek_api(analysis_prompt)
            return self._parse_analysis_result(result)
        except Exception as e:
            print(f"Feedback analysis failed: {e}")
            # Return basic analysis result
            return self._basic_analysis(feedback)
    
    def _build_analysis_prompt(self, feedback: UserFeedback, 
                             previous_feedbacks: List[UserFeedback]) -> str:
        """Build analysis prompt"""
        
        # Build historical feedback summary
        history_summary = ""
        if previous_feedbacks:
            recent_feedbacks = sorted(previous_feedbacks, 
                                    key=lambda x: x.created_at, reverse=True)[:5]
            history_summary = "\nHistorical feedback summary:\n"
            for i, hist_feedback in enumerate(recent_feedbacks, 1):
                history_summary += f"{i}. Rating: {hist_feedback.rating_score}/5, "
                if hist_feedback.rating_comment:
                    history_summary += f"Comment: {hist_feedback.rating_comment}, "
                history_summary += f"Mood: {hist_feedback.mood}\n"
        
        prompt = f"""You are a professional meditation content analysis expert. Please analyze the following user feedback and provide detailed improvement suggestions.

Current feedback:
- User ID: {feedback.user_id}
- Rating: {feedback.rating_score}/5 stars
- Comment: {feedback.rating_comment or "No comment"}
- Mood at the time: {feedback.mood}
- Description at the time: {feedback.context}
- Feedback time: {feedback.created_at.strftime('%Y-%m-%d %H:%M:%S')}
{history_summary}

Please analyze from the following perspectives:

1. Key Issue Identification:
   - Main problems the user may have encountered
   - Content quality deficiencies
   - Personalization level issues

2. Improvement Suggestions:
   - Content adjustment suggestions
   - Style optimization suggestions
   - Personalization improvement directions

3. User Preference Analysis:
   - User's preferred content types
   - User's preferred guidance style
   - User's preferred duration and rhythm

4. Next Meditation Guidance Suggestions:
   - Targeted content adjustments
   - Style and tone optimization
   - Personalization element enhancement

Please return analysis results in JSON format:
{{
    "key_issues": ["Issue 1", "Issue 2"],
    "improvement_suggestions": ["Suggestion 1", "Suggestion 2"],
    "user_preferences": {{
        "content_style": "Describe user's preferred content style",
        "guidance_tone": "Describe user's preferred guidance tone",
        "duration_preference": "User's preferred duration",
        "personalization_level": "User's preferred personalization level"
    }},
    "next_meditation_guidance": "Detailed next meditation guidance suggestions"
}}

Please ensure the analysis is accurate, specific, and actionable."""

        return prompt
    
    def _call_deepseek_api(self, prompt: str) -> str:
        """Call DeepSeek API for analysis"""
        
        payload = {
            "model": "deepseek-chat",
            "messages": [
                {
                    "role": "system",
                    "content": "你是一个专业的冥想内容分析专家，擅长分析用户反馈并提供具体的改进建议。请始终以JSON格式返回分析结果。"
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            "temperature": 0.3,  # 较低的温度确保分析的一致性
            "max_tokens": 1000,
            "top_p": 0.9,
            "stream": False
        }
        
        response = requests.post(
            f"{self.base_url}/v1/chat/completions",
            headers=self.headers,
            json=payload,
            timeout=30
        )
        
        if response.status_code != 200:
            raise Exception(f"API request failed: {response.status_code}")
        
        result = response.json()
        if "choices" not in result or len(result["choices"]) == 0:
            raise Exception("Invalid API response format")
        
        return result["choices"][0]["message"]["content"]
    
    def _parse_analysis_result(self, api_response: str) -> Dict[str, Any]:
        """Parse API analysis results"""
        
        try:
            # Try to extract JSON part
            start_idx = api_response.find('{')
            end_idx = api_response.rfind('}') + 1
            
            if start_idx != -1 and end_idx != 0:
                json_str = api_response[start_idx:end_idx]
                result = json.loads(json_str)
                return result
            else:
                raise ValueError("No valid JSON format found")
                
        except (json.JSONDecodeError, ValueError) as e:
            print(f"Failed to parse analysis results: {e}")
            return self._basic_analysis(None)
    
    def _basic_analysis(self, feedback: UserFeedback) -> Dict[str, Any]:
        """Basic analysis (used when API analysis fails)"""
        
        if not feedback:
            return {
                "key_issues": [],
                "improvement_suggestions": [],
                "user_preferences": {},
                "next_meditation_guidance": "Optimize meditation content based on user feedback"
            }
        
        # Basic analysis based on rating
        if feedback.rating_score <= 2:
            key_issues = ["Content may not be personalized enough", "Guidance style may not suit the user"]
            improvement_suggestions = ["Increase personalization elements", "Adjust guidance tone"]
        elif feedback.rating_score <= 3:
            key_issues = ["Content quality needs improvement"]
            improvement_suggestions = ["Optimize content structure", "Enhance practicality"]
        else:
            key_issues = []
            improvement_suggestions = ["Maintain current style", "Fine-tune personalization level"]
        
        return {
            "key_issues": key_issues,
            "improvement_suggestions": improvement_suggestions,
            "user_preferences": {
                "content_style": "Infer user preferences based on rating",
                "guidance_tone": "Gentle guidance",
                "duration_preference": "Moderate",
                "personalization_level": "Medium"
            },
            "next_meditation_guidance": "Adjust content style and personalization level based on user rating"
        }
    
    def _generate_next_meditation_guidance(self, feedback: UserFeedback, 
                                         previous_feedbacks: List[UserFeedback],
                                         analysis_result: Dict[str, Any]) -> str:
        """Generate guidance suggestions for next meditation"""
        
        guidance_prompt = f"""Based on user feedback analysis, generate specific guidance suggestions for the next meditation.

User information:
- Current rating: {feedback.rating_score}/5 stars
- Current mood: {feedback.mood}
- Current description: {feedback.context}
- User comment: {feedback.rating_comment or "No comment"}

Analysis results:
- Key issues: {', '.join(analysis_result.get('key_issues', []))}
- Improvement suggestions: {', '.join(analysis_result.get('improvement_suggestions', []))}
- User preferences: {analysis_result.get('user_preferences', {})}

Please generate detailed guidance suggestions for the next meditation, including:
1. Content style adjustments
2. Guidance tone optimization
3. Personalization element enhancement
4. Specific content improvement directions

Please answer in English, ensuring suggestions are specific and actionable."""

        try:
            result = self._call_deepseek_api(guidance_prompt)
            return result.strip()
        except Exception as e:
            print(f"Failed to generate guidance suggestions: {e}")
            return "Optimize meditation content based on user feedback, increase personalization elements and practicality."

# 创建全局实例
feedback_analysis_service = FeedbackAnalysisService(DEEPSEEK_API_KEY)
