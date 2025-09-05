#!/usr/bin/env python3
"""
Backend server startup script
"""

import os
import sys
import uvicorn
from pathlib import Path

# Add current directory to Python path
current_dir = Path(__file__).parent
app_dir = current_dir / "app"
sys.path.insert(0, str(current_dir))
sys.path.insert(0, str(app_dir))

# Set proxy environment variables (if needed)
os.environ.setdefault("HTTP_PROXY", "http://127.0.0.1:7897")
os.environ.setdefault("HTTPS_PROXY", "http://127.0.0.1:7897")

def main():
    """Start server"""
    print("🚀 Starting MindTuner backend server...")
    print("📍 Server address: http://0.0.0.0:8080")
    print("📖 API documentation: http://localhost:8080/docs")
    print("=" * 50)
    
    try:
        # Start FastAPI server
        uvicorn.run(
            "app.main:app",
            host="0.0.0.0",
            port=8080,
            reload=True,
            log_level="info"
        )
    except KeyboardInterrupt:
        print("\n🛑 Server stopped")
    except Exception as e:
        print(f"❌ Failed to start server: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
