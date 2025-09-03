#!/usr/bin/env python3
"""
测试登录流程
验证登录成功后跳转到个人信息页面的逻辑
"""

import requests
import json

# 配置
BASE_URL = "http://localhost:8080"
TEST_EMAIL = "test@example.com"
TEST_PASSWORD = "test123456"

def test_login_flow():
    """测试登录流程"""
    print("🧪 开始测试登录流程...")
    
    # 1. 测试登录
    print("\n1️⃣ 测试用户登录...")
    login_data = {
        "email": TEST_EMAIL,
        "password": TEST_PASSWORD
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/user/login",
            json=login_data,
            timeout=30
        )
        
        print(f"📊 登录响应状态码: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print("✅ 登录成功!")
            print(f"   UID: {data.get('uid')}")
            print(f"   邮箱: {data.get('email')}")
            print(f"   显示名: {data.get('display_name')}")
            print(f"   消息: {data.get('message')}")
            
            # 2. 验证返回的数据结构
            print("\n2️⃣ 验证返回数据结构...")
            required_fields = ['uid', 'email', 'display_name', 'message']
            missing_fields = [field for field in required_fields if field not in data]
            
            if missing_fields:
                print(f"❌ 缺少必要字段: {missing_fields}")
                return False
            else:
                print("✅ 数据结构完整")
            
            # 3. 验证字段值
            print("\n3️⃣ 验证字段值...")
            if not data.get('uid'):
                print("❌ UID 为空")
                return False
            if not data.get('email'):
                print("❌ 邮箱为空")
                return False
            if not data.get('display_name'):
                print("⚠️ 显示名为空（可能正常）")
            
            print("✅ 字段值验证通过")
            
            return True
        else:
            print(f"❌ 登录失败: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ 网络错误: $e")
        return False
    except Exception as e:
        print(f"❌ 未知错误: $e")
        return False

def test_backend_connection():
    """测试后端连接"""
    print("🔍 测试后端连接...")
    try:
        response = requests.get(f"{BASE_URL}/", timeout=10)
        print(f"📊 连接状态码: {response.status_code}")
        if response.status_code == 200:
            print("✅ 后端连接正常")
            return True
        else:
            print(f"❌ 后端连接异常: {response.text}")
            return False
    except Exception as e:
        print(f"❌ 后端连接失败: {response.text}")
        return False

if __name__ == "__main__":
    print("🚀 开始登录流程测试")
    print("=" * 50)
    
    # 测试后端连接
    if not test_backend_connection():
        print("❌ 后端连接失败，无法继续测试")
        exit(1)
    
    # 测试登录流程
    success = test_login_flow()
    
    print("\n" + "=" * 50)
    if success:
        print("🎉 登录流程测试完成 - 后端登录功能正常")
        print("💡 现在请测试前端登录流程:")
        print("📱 测试步骤:")
        print("   1. 启动前端应用")
        print("   2. 验证主界面显示（包含底部导航栏）")
        print("   3. 点击右上角登录按钮")
        print("   4. 使用测试账户登录")
        print("   5. 验证登录成功后自动跳转到个人信息页面")
        print("   6. 验证个人信息页面显示用户信息")
        print("   7. 验证底部导航栏高亮显示'我的'页面")
        print("   8. 测试其他页面的切换功能")
    else:
        print("❌ 登录流程测试失败 - 请检查后端服务")
