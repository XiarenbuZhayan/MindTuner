from datetime import datetime
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

user = APIRouter()

class User(BaseModel):
    id:int
    username:str
    password:str
    register_time:datetime

@user.post("/register")
def register():
    pass


@user.post("/login")
def login(data:User):
    pass