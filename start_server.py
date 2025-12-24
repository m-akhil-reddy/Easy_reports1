#!/usr/bin/env python3
"""
Startup script for the Medical Report AI FastAPI server
"""

import subprocess
import sys
import os
from pathlib import Path

def check_dependencies():
    """Check if required dependencies are installed"""
    required_packages = [
        'fastapi',
        'uvicorn',
        'python-multipart',
        'pandas',
        'plotly',
        'cryptography',
        'openai',
        'python-dotenv'
    ]
    
    missing_packages = []
    
    for package in required_packages:
        try:
            __import__(package.replace('-', '_'))
        except ImportError:
            missing_packages.append(package)
    
    if missing_packages:
        print("❌ Missing required packages:")
        for package in missing_packages:
            print(f"   - {package}")
        print("\n📦 Installing missing packages...")
        
        try:
            subprocess.check_call([
                sys.executable, '-m', 'pip', 'install'
            ] + missing_packages)
            print("✅ All packages installed successfully!")
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to install packages: {e}")
            return False
    
    return True

def check_optional_dependencies():
    """Check for optional OCR dependencies"""
    optional_packages = {
        'pytesseract': 'pytesseract',
        'PIL': 'Pillow',
        'fitz': 'PyMuPDF'
    }
    
    missing_optional = []
    
    for import_name, package_name in optional_packages.items():
        try:
            __import__(import_name)
        except ImportError:
            missing_optional.append(package_name)
    
    if missing_optional:
        print("⚠️  Optional OCR packages missing (PDF/image processing will be limited):")
        for package in missing_optional:
            print(f"   - {package}")
        print("\n💡 To enable full OCR functionality, install these packages:")
        print("   pip install pytesseract pillow PyMuPDF")
        print("   And install Tesseract OCR from: https://github.com/UB-Mannheim/tesseract/releases")
        print()
    
    return len(missing_optional) == 0

def main():
    """Main startup function"""
    print("🚀 Starting Medical Report AI Server...")
    print("=" * 50)
    
    # Check if we're in the right directory
    current_dir = Path.cwd()
    if not (current_dir / 'Aimodal.py').exists():
        print("❌ Error: Aimodal.py not found in current directory")
        print(f"   Current directory: {current_dir}")
        print("   Please run this script from the directory containing Aimodal.py")
        return 1
    
    # Check dependencies
    print("🔍 Checking dependencies...")
    if not check_dependencies():
        return 1
    
    # Check optional dependencies
    ocr_available = check_optional_dependencies()
    
    print("✅ Dependencies check complete!")
    print()
    
    # Start the server
    print("🌐 Starting FastAPI server...")
    print("📍 Server will be available at: http://127.0.0.1:8000")
    print("📚 API documentation: http://127.0.0.1:8000/docs")
    print("🔄 Press Ctrl+C to stop the server")
    print("=" * 50)
    
    try:
        # Start the FastAPI server
        subprocess.run([
            sys.executable, '-m', 'uvicorn',
            'fastapi_server:app',
            '--host', '127.0.0.1',
            '--port', '8000',
            '--reload'
        ])
    except KeyboardInterrupt:
        print("\n👋 Server stopped by user")
    except Exception as e:
        print(f"❌ Error starting server: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
