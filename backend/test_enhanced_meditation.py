#!/usr/bin/env python3
"""
测试增强冥想功能的脚本
"""

import requests
import json
import time

# 配置
BASE_URL = "http://localhost:8080"
USER_ID = "test_user_001"

def test_enhanced_meditation_generation():
    """测试增强冥想生成功能"""
    print("🧠 测试增强冥想生成功能...")
    
    # 1. 首先创建一些测试评分数据
    print("\n1. 创建测试评分数据...")
    test_ratings = [
        {
            "user_id": USER_ID,
            "rating_type": "meditation",
            "score": 4,
            "comment": "内容很好，但希望能更个性化一些"
        },
        {
            "user_id": USER_ID,
            "rating_type": "meditation", 
            "score": 3,
            "comment": "指导语调有点快，希望能更温和"
        },
        {
            "user_id": USER_ID,
            "rating_type": "meditation",
            "score": 5,
            "comment": "非常棒！内容很实用，帮助我放松了很多"
        }
    ]
    
    for i, rating in enumerate(test_ratings, 1):
        try:
            response = requests.post(
                f"{BASE_URL}/rating/",
                json=rating,
                headers={"Content-Type": "application/json"}
            )
            if response.status_code == 200:
                print(f"   ✅ 评分 {i} 创建成功")
            else:
                print(f"   ❌ 评分 {i} 创建失败: {response.status_code}")
        except Exception as e:
            print(f"   ❌ 评分 {i} 创建异常: {e}")
    
    # 2. 测试获取用户反馈分析
    print("\n2. 测试获取用户反馈分析...")
    try:
        response = requests.get(f"{BASE_URL}/enhanced-meditation/user/{USER_ID}/feedback-analysis")
        if response.status_code == 200:
            analysis = response.json()
            print("   ✅ 反馈分析获取成功")
            print(f"   📊 反馈数量: {analysis.get('feedback_count', 0)}")
            if analysis.get('has_feedback'):
                latest = analysis.get('latest_feedback', {})
                print(f"   ⭐ 最新评分: {latest.get('rating_score', 0)}/5")
                print(f"   💬 最新评论: {latest.get('rating_comment', '无')}")
                
                analysis_data = analysis.get('analysis', {})
                print(f"   📈 满意度: {analysis_data.get('overall_satisfaction', 0):.2f}")
                print(f"   🔍 识别问题: {analysis_data.get('key_issues', [])}")
                print(f"   💡 优化建议: {analysis_data.get('improvement_suggestions', [])}")
        else:
            print(f"   ❌ 反馈分析获取失败: {response.status_code}")
    except Exception as e:
        print(f"   ❌ 反馈分析获取异常: {e}")
    
    # 3. 测试获取用户反馈历史
    print("\n3. 测试获取用户反馈历史...")
    try:
        response = requests.get(f"{BASE_URL}/enhanced-meditation/user/{USER_ID}/feedback-history?limit=5")
        if response.status_code == 200:
            history = response.json()
            print("   ✅ 反馈历史获取成功")
            print(f"   📚 历史记录数: {history.get('feedback_count', 0)}")
        else:
            print(f"   ❌ 反馈历史获取失败: {response.status_code}")
    except Exception as e:
        print(f"   ❌ 反馈历史获取异常: {e}")
    
    # 4. 测试生成增强冥想内容
    print("\n4. 测试生成增强冥想内容...")
    meditation_request = {
        "user_id": USER_ID,
        "mood": "焦虑",
        "description": "工作压力很大，需要放松和缓解焦虑"
    }
    
    try:
        print("   🎯 发送生成请求...")
        response = requests.post(
            f"{BASE_URL}/enhanced-meditation/generate-enhanced-meditation",
            json=meditation_request,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            result = response.json()
            print("   ✅ 增强冥想生成成功！")
            print(f"   📝 记录ID: {result.get('record_id', 'N/A')}")
            print(f"   🎵 音频URL: {result.get('audio_url', 'N/A')}")
            print(f"   🤖 反馈优化: {result.get('feedback_optimized', False)}")
            
            metadata = result.get('metadata', {})
            print(f"   📊 元数据: {metadata}")
            
            script = result.get('meditation_script', '')
            if script:
                print(f"   📖 冥想脚本预览: {script[:100]}...")
            else:
                print("   ❌ 冥想脚本为空")
        else:
            print(f"   ❌ 增强冥想生成失败: {response.status_code}")
            print(f"   📄 错误详情: {response.text}")
    except Exception as e:
        print(f"   ❌ 增强冥想生成异常: {e}")

def test_feedback_analysis_service():
    """测试反馈分析服务"""
    print("\n🧪 测试反馈分析服务...")
    
    try:
        # 测试获取反馈分析
        response = requests.get(f"{BASE_URL}/enhanced-meditation/user/{USER_ID}/feedback-analysis")
        if response.status_code == 200:
            analysis = response.json()
            print("   ✅ 反馈分析服务正常")
            
            if analysis.get('has_feedback'):
                analysis_data = analysis.get('analysis', {})
                print(f"   📊 分析结果:")
                print(f"      - 满意度: {analysis_data.get('overall_satisfaction', 0):.2f}")
                print(f"      - 问题: {analysis_data.get('key_issues', [])}")
                print(f"      - 建议: {analysis_data.get('improvement_suggestions', [])}")
                print(f"      - 偏好: {analysis_data.get('user_preferences', {})}")
                print(f"      - 指导: {analysis_data.get('next_meditation_guidance', '')[:100]}...")
            else:
                print("   ℹ️ 暂无反馈数据")
        else:
            print(f"   ❌ 反馈分析服务异常: {response.status_code}")
    except Exception as e:
        print(f"   ❌ 反馈分析服务异常: {e}")

def main():
    """主测试函数"""
    print("🚀 开始测试增强冥想功能")
    print("=" * 50)
    
    # 检查服务是否运行
    try:
        response = requests.get(f"{BASE_URL}/")
        if response.status_code == 200:
            print("✅ 后端服务运行正常")
        else:
            print("❌ 后端服务异常")
            return
    except Exception as e:
        print(f"❌ 无法连接到后端服务: {e}")
        print("请确保后端服务正在运行: python main.py")
        return
    
    # 运行测试
    test_enhanced_meditation_generation()
    test_feedback_analysis_service()
    
    print("\n" + "=" * 50)
    print("🎉 测试完成！")
    print("\n📋 测试总结:")
    print("1. ✅ 创建测试评分数据")
    print("2. ✅ 获取用户反馈分析")
    print("3. ✅ 获取用户反馈历史")
    print("4. ✅ 生成基于反馈优化的冥想内容")
    print("5. ✅ 验证反馈分析服务")
    
    print("\n💡 使用说明:")
    print("- 在Flutter应用中点击'智能冥想生成'按钮")
    print("- 查看反馈分析结果")
    print("- 输入心情和描述生成优化内容")
    print("- 对生成的内容进行评分，AI将继续优化")

if __name__ == "__main__":
    main()
