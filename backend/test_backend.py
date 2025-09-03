#!/usr/bin/env python3
"""
Backend API test script
Used to verify if the backend service is working properly
"""

import requests
import json
import time

# Configuration
BASE_URL = "http://localhost:8080"
TEST_USER_ID = "test-user-123"
TEST_MOOD = "stressed"
TEST_DESCRIPTION = "I have a lot of work to do and feel overwhelmed"

def test_root_endpoint():
    """Test root endpoint"""
    print("🔍 Testing root endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/", timeout=10)
        print(f"✅ Status code: {response.status_code}")
        print(f"📄 Response: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_meditation_generation():
    """Test meditation generation"""
    print("\n🎯 Testing meditation generation...")
    
    url = f"{BASE_URL}/meditation/generate-meditation"
    data = {
        "user_id": TEST_USER_ID,
        "mood": TEST_MOOD,
        "description": TEST_DESCRIPTION
    }
    
    try:
        print(f"📤 Sending request to: {url}")
        print(f"📝 Request data: {json.dumps(data, indent=2)}")
        
        response = requests.post(
            url,
            json=data,
            headers={"Content-Type": "application/json"},
            timeout=120  # 2 minutes timeout
        )
        
        print(f"📊 Status code: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Meditation generation successful!")
            print(f"📋 Record ID: {result.get('record_id')}")
            print(f"📝 Script length: {len(result.get('meditation_script', ''))} characters")
            print(f"🎵 Audio URL: {result.get('audio_url')}")
            return True
        else:
            print(f"❌ Request failed: {response.status_code}")
            print(f"📄 Error response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Request exception: {e}")
        return False

def test_network_connectivity():
    """Test network connectivity"""
    print("\n🌐 Testing network connectivity...")
    
    test_urls = [
        "https://www.google.com",
        "https://www.baidu.com",
        "https://api.deepseek.com"
    ]
    
    for url in test_urls:
        try:
            response = requests.get(url, timeout=10)
            print(f"✅ {url} - Status code: {response.status_code}")
        except Exception as e:
            print(f"❌ {url} - Error: {e}")

def main():
    """Main test function"""
    print("🚀 Starting backend API tests...")
    print(f"📍 Target address: {BASE_URL}")
    print("=" * 50)
    
    # Test 1: Root endpoint
    root_success = test_root_endpoint()
    
    # Test 2: Network connectivity
    test_network_connectivity()
    
    # Test 3: Meditation generation
    if root_success:
        meditation_success = test_meditation_generation()
    else:
        print("\n⚠️ Skipping meditation generation test (root endpoint test failed)")
        meditation_success = False
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Test results summary:")
    print(f"   Root endpoint test: {'✅ Passed' if root_success else '❌ Failed'}")
    print(f"   Meditation generation test: {'✅ Passed' if meditation_success else '❌ Failed'}")
    
    if root_success and meditation_success:
        print("\n🎉 All tests passed! Backend service is running normally.")
    else:
        print("\n⚠️ Some tests failed, please check backend configuration.")

if __name__ == "__main__":
    main()
