import requests
import json

# Test the server with text input
url = "http://127.0.0.1:8000/analyze-report"
data = {
    "patient_name": "Test Patient",
    "text_input": "Hemoglobin: 12.5 g/dl, Blood Sugar: 95 mg/dl, WBC: 8000 cells/cu mm"
}

try:
    response = requests.post(url, json=data)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Error: {e}")
