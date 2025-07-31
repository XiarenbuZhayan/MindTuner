from pydantic import BaseModel, EmailStr

class registerUser(BaseModel):
    email:EmailStr
    password:str
    display_name:str

class loginUser(BaseModel):
    email:EmailStr
    password:str
