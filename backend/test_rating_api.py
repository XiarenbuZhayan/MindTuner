import requests
import json
from datetime import datetime

# 后端API基础URL
BASE_URL = "http://localhost:8080"

def test_rating_api():
    """测试评分API的各个功能"""
    
    print("=== 评分API测试开始 ===\n")
    
    # 测试1: 健康检查
    print("1. 测试健康检查...")
    try:
        response = requests.get(f"{BASE_URL}/rating/health")
        if response.status_code == 200:
            print("✓ 健康检查通过")
            print(f"   响应: {response.json()}")
        else:
            print(f"✗ 健康检查失败: {response.status_code}")
    except Exception as e:
        print(f"✗ 健康检查异常: {e}")
    print()

    # 测试2: 创建评分
    print("2. 测试创建评分...")
    test_rating_data = {
        "user_id": "test_user_001",
        "rating_type": "meditation",
        "score": 4,
        "comment": "这是一次很好的冥想体验，让我感到非常放松。"
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/rating/",
            headers={"Content-Type": "application/json"},
            data=json.dumps(test_rating_data)
        )
        
        if response.status_code == 200:
            print("✓ 创建评分成功")
            rating_response = response.json()
            print(f"   评分ID: {rating_response.get('rating_id')}")
            print(f"   评分: {rating_response.get('score')}星")
            print(f"   评论: {rating_response.get('comment')}")
            
            # 保存评分ID用于后续测试
            rating_id = rating_response.get('rating_id')
        else:
            print(f"✗ 创建评分失败: {response.status_code}")
            print(f"   错误信息: {response.text}")
            rating_id = None
    except Exception as e:
        print(f"✗ 创建评分异常: {e}")
        rating_id = None
    print()

    # 测试3: 创建心情评分
    print("3. 测试创建心情评分...")
    mood_rating_data = {
        "user_id": "test_user_001",
        "rating_type": "mood",
        "score": 5,
        "comment": "今天心情很好，充满正能量！"
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/rating/",
            headers={"Content-Type": "application/json"},
            data=json.dumps(mood_rating_data)
        )
        
        if response.status_code == 200:
            print("✓ 创建心情评分成功")
            mood_response = response.json()
            print(f"   评分: {mood_response.get('score')}星")
        else:
            print(f"✗ 创建心情评分失败: {response.status_code}")
    except Exception as e:
        print(f"✗ 创建心情评分异常: {e}")
    print()

    # 测试4: 获取用户评分列表
    print("4. 测试获取用户评分列表...")
    try:
        response = requests.get(f"{BASE_URL}/rating/user/test_user_001")
        
        if response.status_code == 200:
            ratings = response.json()
            print(f"✓ 获取用户评分成功，共{len(ratings)}条记录")
            for i, rating in enumerate(ratings[:3]):  # 只显示前3条
                print(f"   {i+1}. {rating.get('rating_type')} - {rating.get('score')}星")
        else:
            print(f"✗ 获取用户评分失败: {response.status_code}")
    except Exception as e:
        print(f"✗ 获取用户评分异常: {e}")
    print()

    # 测试5: 获取特定评分记录
    if rating_id:
        print("5. 测试获取特定评分记录...")
        try:
            response = requests.get(f"{BASE_URL}/rating/{rating_id}")
            
            if response.status_code == 200:
                rating = response.json()
                print("✓ 获取特定评分记录成功")
                print(f"   评分ID: {rating.get('rating_id')}")
                print(f"   评分: {rating.get('score')}星")
                print(f"   类型: {rating.get('rating_type')}")
            else:
                print(f"✗ 获取特定评分记录失败: {response.status_code}")
        except Exception as e:
            print(f"✗ 获取特定评分记录异常: {e}")
        print()

    # 测试6: 更新评分
    if rating_id:
        print("6. 测试更新评分...")
        update_data = {
            "score": 5,
            "comment": "更新后的评论：这次冥想体验非常棒！"
        }
        
        try:
            response = requests.put(
                f"{BASE_URL}/rating/{rating_id}",
                headers={"Content-Type": "application/json"},
                data=json.dumps(update_data)
            )
            
            if response.status_code == 200:
                print("✓ 更新评分成功")
                updated_rating = response.json()
                print(f"   新评分: {updated_rating.get('score')}星")
                print(f"   新评论: {updated_rating.get('comment')}")
            else:
                print(f"✗ 更新评分失败: {response.status_code}")
        except Exception as e:
            print(f"✗ 更新评分异常: {e}")
        print()

    # 测试7: 获取用户评分统计
    print("7. 测试获取用户评分统计...")
    try:
        response = requests.get(f"{BASE_URL}/rating/user/test_user_001/statistics")
        
        if response.status_code == 200:
            stats = response.json()
            print("✓ 获取用户评分统计成功")
            print(f"   总评分数: {stats.get('total_ratings')}")
            print(f"   平均评分: {stats.get('average_score')}")
            print(f"   评分分布: {stats.get('score_distribution')}")
        else:
            print(f"✗ 获取用户评分统计失败: {response.status_code}")
    except Exception as e:
        print(f"✗ 获取用户评分统计异常: {e}")
    print()

    # 测试8: 获取所有评分统计
    print("8. 测试获取所有评分统计...")
    try:
        response = requests.get(f"{BASE_URL}/rating/statistics/all")
        
        if response.status_code == 200:
            stats = response.json()
            print("✓ 获取所有评分统计成功")
            print(f"   总评分数: {stats.get('total_ratings')}")
            print(f"   平均评分: {stats.get('average_score')}")
        else:
            print(f"✗ 获取所有评分统计失败: {response.status_code}")
    except Exception as e:
        print(f"✗ 获取所有评分统计异常: {e}")
    print()

    # 测试9: 批量创建评分
    print("9. 测试批量创建评分...")
    batch_data = [
        {
            "user_id": "test_user_002",
            "rating_type": "general",
            "score": 3,
            "comment": "一般般的体验"
        },
        {
            "user_id": "test_user_002",
            "rating_type": "meditation",
            "score": 4,
            "comment": "冥想效果不错"
        }
    ]
    
    try:
        response = requests.post(
            f"{BASE_URL}/rating/batch",
            headers={"Content-Type": "application/json"},
            data=json.dumps(batch_data)
        )
        
        if response.status_code == 200:
            batch_results = response.json()
            print(f"✓ 批量创建评分成功，创建了{len(batch_results)}条记录")
        else:
            print(f"✗ 批量创建评分失败: {response.status_code}")
    except Exception as e:
        print(f"✗ 批量创建评分异常: {e}")
    print()

    print("=== 评分API测试完成 ===")

if __name__ == "__main__":
    test_rating_api()
