import os
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import httpx
from dotenv import load_dotenv

load_dotenv()

deep = APIRouter()

DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY")

print("DeepSeek API Key:", os.getenv("DEEPSEEK_API_KEY"))
print("DeepSeek API Key:", DEEPSEEK_API_KEY)

class ChatRequest(BaseModel):
    messages: list[dict]  # 格式: [{"role": "user", "content": "你的问题"}]
    model: str = "deepseek-chat"  # 默认模型

@deep.post("/chat")
async def chat_with_deepseek(request: ChatRequest):
    url = "https://api.deepseek.com/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {DEEPSEEK_API_KEY}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": request.model,
        "messages": request.messages,
        "max_tokens": 2048
    }

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(url, headers=headers, json=payload, timeout=30)
            response.raise_for_status()
            return response.json()["choices"][0]["message"]["content"]
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail="DeepSeek API Call failed")