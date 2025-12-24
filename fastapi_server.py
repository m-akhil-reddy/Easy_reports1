from fastapi import FastAPI, File, UploadFile, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import os
import json
import re
import pandas as pd
from datetime import datetime
from typing import List, Dict, Any, Optional
import tempfile
import shutil

# Import the AI model functions from Aimodal.py
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Import only the necessary functions, avoiding Streamlit dependencies
try:
    # Import the core functions we need
    from Aimodal import (
        clean_and_normalize_text,
        extract_parameters_with_ner,
        classify_tests,
        compute_health_status,
        generate_explanations,
        calculate_health_score,
        setup_database,
        save_report_to_db,
        load_reports_from_db
    )
    
    # Define our own text extraction function to avoid Streamlit
    def extract_text_from_source(uploaded_file):
        """Extracts raw text from PDF, image, or plain text."""
        if not uploaded_file:
            return None

        file_extension = os.path.splitext(uploaded_file.name)[1].lower()
        raw_text = ""

        try:
            if file_extension == ".pdf":
                try:
                    import fitz  # PyMuPDF
                    pdf_bytes = uploaded_file.getvalue()
                    doc = fitz.open(stream=pdf_bytes, filetype="pdf")
                    
                    # Check if the PDF is scanned
                    is_scanned = all(len(page.get_text().strip()) == 0 for page in doc)
                    
                    if is_scanned:
                        try:
                            import pytesseract
                            from PIL import Image
                            for page in doc:
                                pix = page.get_pixmap(dpi=300)
                                img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
                                raw_text += pytesseract.image_to_string(img)
                        except ImportError:
                            return {"error": "OCR not available for scanned PDF"}
                    else:
                        for page in doc:
                            raw_text += page.get_text()
                    doc.close()
                except ImportError:
                    return {"error": "PDF processing not available"}

            elif file_extension in [".jpg", ".jpeg", ".png"]:
                try:
                    import pytesseract
                    from PIL import Image
                    img = Image.open(uploaded_file)
                    raw_text = pytesseract.image_to_string(img)
                except ImportError:
                    return {"error": "Image OCR not available"}

            elif file_extension == ".txt":
                raw_text = uploaded_file.read().decode("utf-8")

        except Exception as e:
            return {"error": f"Error processing file: {e}"}

        return {"raw_text": raw_text}

except ImportError as e:
    print(f"Warning: Could not import from Aimodal.py: {e}")
    print("Using simplified fallback functions...")
    
    # Fallback functions if Aimodal.py is not available
    def clean_and_normalize_text(raw_text_data):
        return {"clean_text": raw_text_data.get("raw_text", "")}
    
    def extract_parameters_with_ner(clean_text_data):
        return []
    
    def classify_tests(extracted_params):
        return extracted_params
    
    def compute_health_status(extracted_params):
        return extracted_params
    
    def generate_explanations(analyzed_params, use_llm=False):
        return analyzed_params
    
    def calculate_health_score(analyzed_params):
        return 0, "⚪"
    
    def setup_database():
        pass
    
    def save_report_to_db(patient_name, report_date, report_data):
        pass
    
    def load_reports_from_db(patient_name):
        return []
    
    def extract_text_from_source(uploaded_file):
        return {"error": "AI model not available"}

# Common function for file text extraction (works with both AI model and fallback)
def extract_text_from_file(file_path, filename):
    """Extract text from a file directly"""
    try:
        file_extension = os.path.splitext(filename)[1].lower()
        raw_text = ""

        if file_extension == ".pdf":
            try:
                import fitz  # PyMuPDF
                doc = fitz.open(file_path)
                
                # Check if the PDF is scanned
                is_scanned = all(len(page.get_text().strip()) == 0 for page in doc)
                
                if is_scanned:
                    try:
                        import pytesseract
                        from PIL import Image
                        for page in doc:
                            pix = page.get_pixmap(dpi=300)
                            img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
                            raw_text += pytesseract.image_to_string(img)
                    except ImportError:
                        return {"error": "OCR not available for scanned PDF"}
                else:
                    for page in doc:
                        raw_text += page.get_text()
                doc.close()
            except ImportError:
                return {"error": "PDF processing not available"}

        elif file_extension in [".jpg", ".jpeg", ".png"]:
            try:
                import pytesseract
                from PIL import Image
                img = Image.open(file_path)
                raw_text = pytesseract.image_to_string(img)
            except ImportError:
                return {"error": "Image OCR not available"}

        elif file_extension == ".txt":
            with open(file_path, 'r', encoding='utf-8') as f:
                raw_text = f.read()

        return {"raw_text": raw_text}

    except Exception as e:
        return {"error": f"Error processing file: {e}"}

app = FastAPI(title="Medical Report AI API", version="1.0.0")

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize database
setup_database()

@app.get("/")
async def root():
    return {"message": "Medical Report AI API is running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.post("/analyze-report")
async def analyze_report(request: Request):
    """
    Analyze a medical report from file upload or text input
    """
    try:
        content_type = request.headers.get("content-type", "")
        
        # Handle multipart form data (file upload)
        if "multipart/form-data" in content_type:
            form = await request.form()
            patient_name = form.get("patient_name")
            file = form.get("file")
            text_input = None
            
            if not patient_name:
                raise HTTPException(status_code=400, detail="Patient name is required")
            
            if not file:
                raise HTTPException(status_code=400, detail="No file provided")
            
            # Save uploaded file temporarily
            with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file.filename)[1]) as tmp_file:
                content = await file.read()
                tmp_file.write(content)
                tmp_file_path = tmp_file.name
            
            try:
                # Create a mock uploaded file object for the existing function
                class MockUploadedFile:
                    def __init__(self, file_path, filename):
                        self.name = filename
                        self._file_path = file_path
                    
                    def getvalue(self):
                        with open(self._file_path, 'rb') as f:
                            return f.read()
                
                # Extract text directly from the file
                raw_text_data = extract_text_from_file(tmp_file_path, file.filename)
                
                # Debug: Print the extracted text
                if raw_text_data and raw_text_data.get("raw_text"):
                    print(f"Extracted text length: {len(raw_text_data['raw_text'])}")
                    print(f"First 200 chars: {raw_text_data['raw_text'][:200]}")
                else:
                    print("No text extracted from file")
                    
            finally:
                # Clean up temporary file
                if os.path.exists(tmp_file_path):
                    os.unlink(tmp_file_path)
        
        # Handle JSON data (text input)
        else:
            body = await request.json()
            patient_name = body.get("patient_name")
            text_input = body.get("text_input")
            file = None
            
            if not patient_name:
                raise HTTPException(status_code=400, detail="Patient name is required")
            
            if not text_input:
                raise HTTPException(status_code=400, detail="No text input provided")
            
            raw_text_data = {"raw_text": text_input}
        
        # Validate input
        if not raw_text_data or not raw_text_data.get("raw_text", "").strip():
            raise HTTPException(status_code=400, detail="Could not extract text from the provided input")
        
        # Process the text through the AI pipeline
        clean_text_data = clean_and_normalize_text(raw_text_data)
        extracted_params = extract_parameters_with_ner(clean_text_data)
        
        if not extracted_params:
            raise HTTPException(status_code=400, detail="No valid medical parameters found in the report")
        
        # Run the full analysis pipeline
        classified_params = classify_tests(extracted_params)
        analyzed_params = compute_health_status(classified_params)
        final_params = generate_explanations(analyzed_params, use_llm=False)  # Disable LLM for API
        score, emoji = calculate_health_score(final_params)
        
        # Create the final output
        report_date = datetime.now().strftime("%Y-%m-%d")
        final_output = {
            "patient_name": patient_name,
            "report_date": report_date,
            "health_score": {
                "score": score,
                "emoji": emoji,
                "status": "Excellent" if score >= 90 else "Average" if score >= 70 else "Needs Attention"
            },
            "tests": final_params,
            "summary": {
                "total_tests": len(final_params),
                "normal_tests": len([t for t in final_params if t["status"] == "Normal"]),
                "abnormal_tests": len([t for t in final_params if t["status"] != "Normal"]),
                "regular_tests": len([t for t in final_params if t["category"] == "regular"]),
                "periodic_tests": len([t for t in final_params if t["category"] == "periodic"])
            }
        }
        
        # Save to database
        save_report_to_db(patient_name, report_date, final_output)
        
        # Load historical data for trends
        historical_reports = load_reports_from_db(patient_name)
        final_output["historical_data"] = historical_reports
        
        return JSONResponse(content=final_output, media_type="application/json; charset=utf-8")
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@app.get("/patient-history/{patient_name}")
async def get_patient_history(patient_name: str):
    """
    Get historical reports for a patient
    """
    try:
        historical_reports = load_reports_from_db(patient_name)
        return JSONResponse(content={"patient_name": patient_name, "reports": historical_reports})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving patient history: {str(e)}")

@app.get("/test-patterns")
async def get_test_patterns():
    """
    Get available test patterns and their normal ranges
    """
    # This would return the medical_tests dictionary from Aimodal.py
    # For now, return a simplified version
    return JSONResponse(content={
        "message": "Test patterns available",
        "supported_tests": [
            "Hemoglobin", "P.C.V", "R.B.C", "W.B.C", "Platelet Count",
            "Serum Creatinine", "Blood Urea", "Serum Sodium", "Serum Potassium",
            "SGOT", "SGPT", "Albumin", "INR", "Blood Sugar"
        ]
    })

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=5000, reload=True)
