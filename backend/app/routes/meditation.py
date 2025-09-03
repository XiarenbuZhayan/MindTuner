import requests
import json
import time
import asyncio
import uuid
from services.tts_service import TTSService

from dataclasses import dataclass
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, Optional
from config.config import DEEPSEEK_API_KEY

deepseek_api_key = DEEPSEEK_API_KEY

from services.database_service import MeditationDatabaseService


medi = APIRouter()
db_service = MeditationDatabaseService()

class SimpleMeditationRequest(BaseModel):
    mood:str        # User's current mood
    description: str  # Brief description of current state



# DeepSeek API wrapper for generating meditation scripts
class DeepSeekMeditationAPI:

    def __init__(self, api_key: str, base_url: str = "https://api.deepseek.com"):
        self.api_key = api_key
        self.base_url = base_url
        self.headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }

    def _get_prompt_template(self, request: SimpleMeditationRequest) -> str:
        """Generate prompt template based on user's mood and description"""
        
        # Core prompt template
        template = f"""You are a compassionate meditation guide with expertise in mindfulness and emotional wellness. Create a meditation script for someone who is feeling {request.mood} and describes their current state as: "{request.description}"

**Script Requirements:**
- Duration: 2-3 minutes when read at a calm, steady pace
- Language: Gentle, soothing, and supportive tone
- Structure: Begin with a short opening to settle in, smoothly transition into the main practice, and end with a gentle closing to return to daily life
- Include timing cues as natural guidance, such as: "Now, let's pause for a few moments," "Let's breathe deeply together," "Let's sit in silence for a little while"
- Address their specific emotional state with empathy
- Provide practical, immediate relief techniques
- Keep it secular and accessible to all backgrounds
- Use present-tense, direct guidance ("Notice...", "Allow...", "Feel...")

**Personalization Guidelines:**
{self._get_mood_specific_guidance(request)}

**Format:**
- Write as a continuous script meant to be read aloud
- All instructions must use first-person, immersive language, as if you are guiding the user directly ("Let's...", "Now we'll...", "Take a moment to...")
- Do not use any section headers, time estimates, or narrator-style phrases
- All timing or breathing cues should be embedded as direct instructions (e.g., "Now, let's take a deep breath together and pause for a few seconds.")
- End with a gentle transition back to their day

Generate a complete meditation script that directly addresses their current emotional state and provides immediate comfort and grounding. **Do not use any narrator-style phrases, section headers, or time labels. All instructions must be in first-person, immersive language.**"""

        return template


    def _get_mood_specific_guidance(self, request: SimpleMeditationRequest) -> str:
        """Get mood-specific guidance for the meditation script"""
        
        mood_lower = request.mood.lower()
        description_lower = request.description.lower()
        
        # Mood-specific guidance
        mood_guidance = {
            "anxious": "Focus on grounding techniques, slow breathing, and present-moment awareness. Use reassuring language about safety and control.",
            "stressed": "Emphasize releasing tension, letting go, and finding calm. Include body relaxation and mental decluttering.",
            "sad": "Provide gentle companionship, self-compassion, and emotional acceptance. Avoid forcing positivity.",
            "overwhelmed": "Focus on simplifying, one breath at a time. Create space and mental clarity.",
            "angry": "Guide toward cooling down, releasing heat, and finding inner peace. Use calming imagery.",
            "tired": "Offer gentle energy renewal while honoring their need for rest. Balance restoration with gentle awakening.",
            "lonely": "Provide warm, connecting language. Focus on self-love and universal connection.",
            "frustrated": "Help release tension and find patience. Guide toward acceptance and letting go.",
            "worried": "Address future-focused anxiety. Bring attention to the present moment and what's actually okay right now.",
            "restless": "Provide grounding and settling techniques. Help find stillness within movement."
        }
        
        # Default guidance for unrecognized moods
        default_guidance = "Acknowledge their current emotional state with acceptance and provide gentle guidance toward inner calm and balance."
        
        # Find matching guidance
        guidance = default_guidance
        for mood_key, mood_advice in mood_guidance.items():
            if mood_key in mood_lower:
                guidance = mood_advice
                break
        
        # Add context from description
        context_additions = []
        
        if any(word in description_lower for word in ["work", "job", "office", "meeting"]):
            context_additions.append("Reference work-related stress and the need to find calm amidst professional demands.")
        
        if any(word in description_lower for word in ["sleep", "tired", "exhausted", "bed"]):
            context_additions.append("Address fatigue and the balance between rest and gentle alertness.")
        
        if any(word in description_lower for word in ["relationship", "partner", "friend", "family"]):
            context_additions.append("Acknowledge interpersonal challenges with compassion for all involved.")
        
        if any(word in description_lower for word in ["pain", "hurt", "ache", "sick"]):
            context_additions.append("Offer gentle comfort for physical discomfort without medical advice.")
        
        if context_additions:
            guidance += " Additionally: " + " ".join(context_additions)
        
        return guidance

    async def generate_meditation_script(self, request: SimpleMeditationRequest) -> Dict[str, Any]:
        """Generate meditation script based on mood and description"""
        
        try:
            # Build the prompt
            prompt = self._get_prompt_template(request)
            
            # API request payload
            payload = {
                "model": "deepseek-chat",
                "messages": [
                    {
                        "role": "system",
                        "content": "You are an expert meditation guide who creates personalized, compassionate meditation scripts. Your responses should be warm, practical, and immediately helpful for the user's current emotional state."
                    },
                    {
                        "role": "user", 
                        "content": prompt
                    }
                ],
                "temperature": 0.8,  # Slightly higher for more personalized responses
                "max_tokens": 256,  # Appropriate for 2-3 minute scripts
                "top_p": 0.9,
                "frequency_penalty": 0.2,
                "presence_penalty": 0.1,
                "stream": False
            }
            
            # Send API request
            response = requests.post(
                f"{self.base_url}/v1/chat/completions",
                headers=self.headers,
                json=payload,
                timeout=30
            )
            
            # Check response status
            if response.status_code != 200:
                return {
                    "success": False,
                    "error": f"API request failed: {response.status_code}",
                    "details": response.text
                }
            
            # Parse response
            result = response.json()
            
            if "choices" not in result or len(result["choices"]) == 0:
                return {
                    "success": False,
                    "error": "Invalid API response format",
                    "details": result
                }
            
            # Extract generated script
            script_content = result["choices"][0]["message"]["content"]
            
            # Post-process the script
            processed_script = self._post_process_script(script_content, request)
            
            return {
                "success": True,
                "script": processed_script,
                "metadata": {
                    "mood": request.mood,
                    "description": request.description,
                    "estimated_duration": "2-3 minutes",
                    "generated_at": time.time(),
                    "token_usage": result.get("usage", {})
                }
            }
            
        except requests.exceptions.Timeout:
            return {
                "success": False,
                "error": "API request timeout",
                "details": "Request took longer than 30 seconds"
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
        
    def _post_process_script(self, script: str, request: SimpleMeditationRequest) -> str:
        """Post-process the meditation script"""
        
        processed = script.strip()
        
        # Ensure proper opening if missing
        if not any(start_word in processed[:50].lower() for start_word in ["welcome", "hello", "let's", "take", "find"]):
            processed = f"Let's take a moment together to find some peace. {processed}"
        
        # Ensure gentle closing if missing
        if not any(end_word in processed[-100:].lower() for end_word in ["gently", "slowly", "when you're ready", "take your time"]):
            processed += "\n\nWhen you're ready, gently open your eyes and carry this sense of calm with you."
        
        return processed
        
# Service layer
class MeditationService:

    def __init__(self, deepseek_api_key: str):
        self.api = DeepSeekMeditationAPI(deepseek_api_key)

    async def create_meditation_for_mood(self, mood: str, description: str) -> Dict[str, Any]:
        
        # Create request object
        request = SimpleMeditationRequest(
            mood=mood.strip(),
            description=description.strip()
        )
        
        # Generate script
        result = await self.api.generate_meditation_script(request)
        
        return result
    

class MoodMeditationRequest(BaseModel):
    user_id: str
    mood: str
    description: str


meditation_service = MeditationService(deepseek_api_key)

@medi.post("/generate-meditation")
async def generate_meditation(request: MoodMeditationRequest):

    try:
        if not deepseek_api_key:
            raise HTTPException(status_code=500, detail="DEEPSEEK_API_KEY is missing")
        
        if not request.user_id.strip():
            raise HTTPException(status_code=400, detail="User ID cannot be empty")
        
        if not request.mood.strip():
            raise HTTPException(status_code=400, detail="Mood cannot be empty")
        
        if not request.description.strip():
            raise HTTPException(status_code=400, detail="Description cannot be empty")
        
        # Generate script
        result = await meditation_service.create_meditation_for_mood(
            request.mood, 
            request.description
        )
        
        if not result["success"]:
            raise HTTPException(
            status_code=502,
            detail={"error": result["error"], "details": result.get("details")}
        )

        # Generate audio and save to storage
        audio_url = None
        try:
            from services.tts_service import TTSService
            tts_service = TTSService()
            audio_url = tts_service.generate_and_store_speech(
                result["script"], 
                str(uuid.uuid4())  # Generate a temporary ID for TTS
            )
        except Exception as e:
            print(f"TTS generation failed: {e}")
            audio_url = None

        # Save meditation record with audio URL
        saved = db_service.save_meditation_record(
            user_id=request.user_id,
            mood=request.mood,
            context=request.description,
            script=result["script"],
            audio_url=audio_url,
        )
        
        return {
            "status": "success",
            "record_id": saved["record_id"],
            "meditation_script": result["script"],
            "audio_url": audio_url,
            "metadata": result["metadata"]
        }
      
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Generation failed: {str(e)}")