from datetime import datetime
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr
from firebase_admin import auth
from firebase_admin.auth import UserRecord
import firebase_admin
from firebase_admin import credentials

from config.config import db
from models.user_model import registerUser, loginUser

user = APIRouter()

class User(BaseModel):
    id: int
    display_name: str
    password: str
    register_time: datetime

class UserResponse(BaseModel):
    uid: str
    email: str
    display_name: str
    message: str

class LoginResponse(BaseModel):
    uid: str
    email: str
    display_name: str
    message: str

@user.post("/register", response_model=UserResponse)
def register(user_data: registerUser):
    """用户注册"""
    try:
        # 检查邮箱是否已存在
        try:
            existing_user = auth.get_user_by_email(user_data.email)
            raise HTTPException(status_code=400, detail="邮箱已被注册")
        except auth.UserNotFoundError:
            pass  # 用户不存在，可以继续注册
        
        # 创建Firebase用户
        user_record = auth.create_user(
            email=user_data.email,
            password=user_data.password,
            display_name=user_data.display_name,
        )

        # 存储用户信息到Firestore
        db.collection("users").document(user_record.uid).set({
            "email": user_data.email,
            "display_name": user_data.display_name,
            "created_at": datetime.now(),
            "last_login": datetime.now(),
        })

        return UserResponse(
            uid=user_record.uid,
            email=user_data.email,
            display_name=user_data.display_name,
            message="注册成功"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"注册错误: {e}")
        raise HTTPException(status_code=500, detail=f"注册失败: {str(e)}")

@user.post("/login", response_model=LoginResponse)
def login(user_data: loginUser):
    """用户登录"""
    try:
        # 验证用户凭据
        user_record = auth.get_user_by_email(user_data.email)
        
        # 检查用户是否在Firestore中存在
        user_doc = db.collection("users").document(user_record.uid).get()
        
        if user_doc.exists:
            # 用户存在，更新最后登录时间
            db.collection("users").document(user_record.uid).update({
                "last_login": datetime.now()
            })
            user_info = user_doc.to_dict()
        else:
            # 用户不存在于Firestore，创建用户记录
            user_info = {
                "email": user_record.email,
                "display_name": user_record.display_name or "",
                "created_at": datetime.now(),
                "last_login": datetime.now(),
            }
            db.collection("users").document(user_record.uid).set(user_info)
        
        return LoginResponse(
            uid=user_record.uid,
            email=user_record.email,
            display_name=user_info.get("display_name", user_record.display_name or ""),
            message="登录成功"
        )
        
    except auth.UserNotFoundError:
        raise HTTPException(status_code=404, detail="用户不存在")
    except Exception as e:
        print(f"登录错误: {e}")
        raise HTTPException(status_code=500, detail=f"登录失败: {str(e)}")

@user.get("/user/{uid}")
def get_user_info(uid: str):
    """获取用户信息"""
    try:
        # 获取Firebase用户信息
        user_record = auth.get_user(uid)
        
        # 获取Firestore中的额外信息
        user_doc = db.collection("users").document(uid).get()
        user_info = user_doc.to_dict() if user_doc.exists else {}
        
        return {
            "uid": uid,
            "email": user_record.email,
            "display_name": user_info.get("display_name", user_record.display_name or ""),
            "created_at": user_info.get("created_at"),
            "last_login": user_info.get("last_login")
        }
        
    except auth.UserNotFoundError:
        raise HTTPException(status_code=404, detail="用户不存在")
    except Exception as e:
        print(f"获取用户信息错误: {e}")
        raise HTTPException(status_code=500, detail=f"获取用户信息失败: {str(e)}")

@user.delete("/user/{uid}")
def delete_user(uid: str):
    """删除用户"""
    try:
        # 删除Firebase用户
        auth.delete_user(uid)
        
        # 删除Firestore中的用户数据
        db.collection("users").document(uid).delete()
        
        return {"message": "用户删除成功"}
        
    except auth.UserNotFoundError:
        raise HTTPException(status_code=404, detail="用户不存在")
    except Exception as e:
        print(f"删除用户错误: {e}")
        raise HTTPException(status_code=500, detail=f"删除用户失败: {str(e)}")