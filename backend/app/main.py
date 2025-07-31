import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from config.config import db
from routes.meditation import medi
from routes.user import user

app = FastAPI()

app.include_router(medi, prefix="/meditation")
app.include_router(user, prefix="/user")

if __name__ == '__main__':
    uvicorn.run("main:app", port=8080, reload=True)
