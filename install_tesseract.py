#!/usr/bin/env python3
"""
Script to help install Tesseract OCR on Windows.
This script will download and provide instructions for manual installation.
"""

import os
import sys
import urllib.request
import zipfile
import shutil
from pathlib import Path

def download_tesseract():
    """Download Tesseract OCR installer for Windows."""
    
    # Tesseract download URL (latest stable version)
    tesseract_url = "https://github.com/UB-Mannheim/tesseract/releases/download/v5.3.3.20231005/tesseract-ocr-w64-setup-5.3.3.20231005.exe"
    
    print("TESSERACT OCR INSTALLATION HELPER")
    print("=" * 50)
    print()
    print("Since Chocolatey installation failed, we'll help you install Tesseract manually.")
    print()
    print("OPTION 1: Download and install manually")
    print(f"1. Download Tesseract from: {tesseract_url}")
    print("2. Run the downloaded installer")
    print("3. During installation, make sure to:")
    print("   - Install to default location (usually C:\\Program Files\\Tesseract-OCR)")
    print("   - Add Tesseract to PATH (this option should be checked by default)")
    print("4. Restart your command prompt/PowerShell after installation")
    print()
    print("OPTION 2: Alternative - Use conda (if you have Anaconda/Miniconda)")
    print("   conda install -c conda-forge tesseract")
    print()
    print("OPTION 3: Alternative - Use pip with tesseract-ocr package")
    print("   pip install tesseract-ocr")
    print()
    print("After installation, verify by running: tesseract --version")
    print()
    
    # Check if we can download the installer
    try:
        print("Attempting to download Tesseract installer...")
        installer_path = "tesseract-installer.exe"
        urllib.request.urlretrieve(tesseract_url, installer_path)
        print(f"SUCCESS: Downloaded installer to {installer_path}")
        print("You can now run this installer to install Tesseract OCR.")
        return True
    except Exception as e:
        print(f"Could not download installer automatically: {e}")
        print("Please download manually from the URL provided above.")
        return False

def check_tesseract_installation():
    """Check if Tesseract is properly installed."""
    try:
        import subprocess
        result = subprocess.run(['tesseract', '--version'], 
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            print("SUCCESS: Tesseract is installed and working!")
            print(f"Version info: {result.stdout.split()[1] if result.stdout else 'Unknown'}")
            return True
        else:
            print("Tesseract is installed but may not be in PATH")
            return False
    except (subprocess.TimeoutExpired, FileNotFoundError, Exception) as e:
        print(f"Tesseract not found: {e}")
        return False

def main():
    print("Checking current Tesseract installation...")
    
    if check_tesseract_installation():
        print("Tesseract is already installed and working!")
        return
    
    print("\nTesseract not found. Starting installation process...")
    download_tesseract()

if __name__ == "__main__":
    main()


