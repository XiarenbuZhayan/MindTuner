from datetime import datetime
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel


from services.gpt_service import generate_meditation_script

medi = APIRouter()

class MeditationRequest(BaseModel):
    mood:str
    context:str

class MeditationResponse(BaseModel):
    id:int
    script:str
    generated_time:datetime


@medi.post("/generate")
def generate_meditation(request:MeditationRequest):
    try:
        script = generate_meditation_script(request.mood, request.context)
        return {"script": script}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@medi.post("/regenerate")
def regenerate_meditation(data:MeditationRequest):
    pass

@medi.post("/tts")
def generate_voice(data:MeditationResponse):
    pass