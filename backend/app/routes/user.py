from datetime import datetime
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from firebase_admin import auth


from config.config import db
from models.user_model import registerUser, loginUser


user = APIRouter()

class User(BaseModel):
    id:int
    display_name:str
    password:str
    register_time:datetime

@user.post("/register")
def register(user:registerUser):
    try:
        # create user
        user_record = auth.create_user(
            email = user.email,
            password = user.password,
            display_name = user.display_name,
        )

        # store user information
        db.collection("user").document(user_record.uid).set({
            "email": user.email,
            "username": user.display_name,
        })

        return {"message": "User registered successfully.", "uid": user_record.uid}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))



@user.post("/login")
def login(user:loginUser):
    
    # front end implement
    pass