from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="MindTuner API")

# -- CORS --
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],       # 生产环境请改成具体域名
    allow_methods=["*"],
    allow_headers=["*"],
)

# -- healthcheck --
@app.get("/ping")
async def ping():
    return {"msg": "pong"}

# -- demo root --
@app.get("/")
async def root():
    return {"message": "Hello, FastAPI!"}

# -- 示例业务端点：生成冥想脚本 --
class ScriptRequest(BaseModel):
    mood: str
    goal: str

@app.post("/generate")
async def generate(req: ScriptRequest):
    if not req.mood or not req.goal:
        raise HTTPException(status_code=400, detail="mood & goal required")
    # TODO: 调用 OpenAI、TTS…
    return {"script": f"Relax, you feel {req.mood} and want to {req.goal}."}
