import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from Aimodal import extract_text_from_source

# Test the text extraction function directly
class MockFile:
    def __init__(self, content, filename):
        self.name = filename
        self.content = content
    
    def getvalue(self):
        return self.content

# Test with text content
test_content = b"""MEDICAL REPORT

Patient: Test Patient
Date: 2024-01-15

LABORATORY RESULTS:

Complete Blood Count (CBC):
- Hemoglobin: 12.5 g/dl
- P.C.V: 38%
- R.B.C: 4.8 million/cu mm
- W.B.C: 7500 cells/cu mm
- Platelet Count: 2.8 lacs/cu mm

Blood Chemistry:
- Blood Sugar: 95 mg/dl
- Serum Creatinine: 0.9 mg/dl
- Blood Urea: 15 mg/dl
"""

mock_file = MockFile(test_content, "test.txt")
result = extract_text_from_source(mock_file)

print("Result:", result)
if result and result.get("raw_text"):
    print("Text extracted successfully!")
    print("Length:", len(result["raw_text"]))
    print("First 200 chars:", result["raw_text"][:200])
else:
    print("No text extracted")
