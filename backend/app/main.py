import os

os.environ.setdefault("HTTP_PROXY", "http://192.168.0.111:10809")
os.environ.setdefault("HTTPS_PROXY", "http://192.168.0.111:10809")

import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from routes.meditation import medi
from routes.user import user
from routes.history import hist
from routes.deepseek_api import deep
from routes.rating import rating_router
from routes.enhanced_meditation import enhanced_meditation_router
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Meditation API", description="API for meditation app")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(medi, prefix="/meditation", tags=["Meditation"])
app.include_router(user, prefix="/user", tags=["User"])
app.include_router(hist, prefix="/history", tags=["History"])
app.include_router(deep, prefix="/deep", tags=["deepseek"])
app.include_router(rating_router, prefix="/rating", tags=["Rating"])
app.include_router(enhanced_meditation_router, prefix="/enhanced-meditation", tags=["Enhanced Meditation"])


@app.get("/")
def read_root():
    return {"message": "Welcome to the Meditation API"}

if __name__ == '__main__':
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)
