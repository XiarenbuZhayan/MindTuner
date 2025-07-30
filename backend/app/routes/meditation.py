from datetime import datetime
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

medi = APIRouter()

class MeditationRequest(BaseModel):
    mood:str
    context:str

class MeditationResponse(BaseModel):
    id:int
    script:str
    generated_time:datetime


@medi.post("/generate")
def generate_meditation_scripts(data:MeditationRequest):
    pass

@medi.post("/regenerate")
def regenerate_meditation_scripts(data:MeditationRequest):
    pass

@medi.post("/tts")
def generate_voice(data:MeditationResponse):
    pass