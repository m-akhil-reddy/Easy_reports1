import requests

# Test file upload to the server
url = "http://127.0.0.1:8000/analyze-report"

# Test with the text file
with open('test_medical_report.txt', 'rb') as f:
    files = {'file': ('test_medical_report.txt', f, 'text/plain')}
    data = {'patient_name': 'Test Patient'}
    
    try:
        response = requests.post(url, files=files, data=data)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text[:500]}...")  # First 500 chars
    except Exception as e:
        print(f"Error: {e}")
