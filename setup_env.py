#!/usr/bin/env python3
"""
Setup script to generate encryption key for the medical report application.
Run this script to generate a .env file with a secure encryption key.
"""

import os
from cryptography.fernet import Fernet

def generate_env_file():
    """Generate a .env file with a new encryption key."""
    
    # Generate a new encryption key
    encryption_key = Fernet.generate_key().decode()
    
    # Create .env file content
    env_content = f"""# Medical Report Application Environment Variables
# Generated on {os.popen('date').read().strip()}

# Encryption key for securing patient data in the database
ENCRYPTION_KEY={encryption_key}

# Optional: OpenAI API key for advanced AI explanations
# OPENAI_API_KEY=your_openai_api_key_here
"""
    
    # Write to .env file
    with open('.env', 'w') as f:
        f.write(env_content)
    
    print("SUCCESS: .env file created successfully!")
    print("SECURITY: Encryption key generated and saved securely.")
    print("\nNEXT STEPS:")
    print("1. Install dependencies: pip install -r requirements.txt")
    print("2. Install Tesseract OCR (see README for instructions)")
    print("3. Run the app: streamlit run Aimodal.py")
    print("\nWARNING: Keep your .env file secure and never commit it to version control!")

if __name__ == "__main__":
    generate_env_file()


