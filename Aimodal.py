import streamlit as st
import re
import pandas as pd
import plotly.express as px
import json
import sqlite3
from cryptography.fernet import Fernet
from datetime import datetime
import os
import openai
from dotenv import load_dotenv

# Optional imports with fallback handling
try:
    import pytesseract
    from PIL import Image
    import fitz  # PyMuPDF
    OCR_AVAILABLE = True
except ImportError as e:
    st.warning(f"Some optional dependencies are not available: {e}")
    st.info("OCR functionality will be limited. For full functionality, please install: pip install pytesseract pillow PyMuPDF")
    OCR_AVAILABLE = False
    pytesseract = None
    Image = None
    fitz = None

# --- ⚙️ Configuration & Security Setup ---

# Load environment variables from a .env file
load_dotenv()

# IMPORTANT: This is the secure way to handle secrets.
# It retrieves the key from the .env file you created.
ENCRYPTION_KEY_STR = os.getenv("ENCRYPTION_KEY")
if not ENCRYPTION_KEY_STR:
    st.warning("ENCRYPTION_KEY environment variable not set! Using temporary key for this session.")
    st.info("For production use, create a .env file with a secure encryption key.")
    # Generate a temporary key for this session
    from cryptography.fernet import Fernet
    ENCRYPTION_KEY = Fernet.generate_key()
    cipher_suite = Fernet(ENCRYPTION_KEY)
else:
    ENCRYPTION_KEY = ENCRYPTION_KEY_STR.encode()
    cipher_suite = Fernet(ENCRYPTION_KEY)
DB_FILE = "patient_reports.db"

# --- 1️⃣ & 2️⃣: Input and Data Extraction Layer (Corrected & Improved) ---

def extract_text_from_source(uploaded_file):
    """Extracts raw text from PDF, image, or plain text with improved PDF handling."""
    if not uploaded_file:
        return None

    file_extension = os.path.splitext(uploaded_file.name)[1].lower()
    raw_text = ""

    try:
        if file_extension == ".pdf":
            if not OCR_AVAILABLE or fitz is None:
                st.error("PDF processing requires PyMuPDF. Please install it with: pip install PyMuPDF")
                return None
            
            pdf_bytes = uploaded_file.getvalue()
            doc = fitz.open(stream=pdf_bytes, filetype="pdf")
            is_scanned = False
            # Check if the PDF is scanned by looking for text content
            if all(len(page.get_text().strip()) == 0 for page in doc):
                 is_scanned = True

            if is_scanned:
                if not OCR_AVAILABLE or pytesseract is None or Image is None:
                    st.error("Scanned PDF detected but OCR is not available. Please install Tesseract OCR and required packages.")
                    st.info("For Windows: Download Tesseract from https://github.com/UB-Mannheim/tesseract/releases")
                    st.info("Then install: pip install pytesseract pillow")
                    return None
                
                st.warning("Scanned PDF detected. Using OCR, which may take longer...")
                for page in doc:
                    # Render page to an image at higher DPI for better OCR
                    pix = page.get_pixmap(dpi=300)
                    img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
                    raw_text += pytesseract.image_to_string(img)
            else:
                for page in doc:
                    raw_text += page.get_text()

        elif file_extension in [".jpg", ".jpeg", ".png"]:
            if not OCR_AVAILABLE or pytesseract is None or Image is None:
                st.error("Image processing requires OCR. Please install Tesseract OCR and required packages.")
                st.info("For Windows: Download Tesseract from https://github.com/UB-Mannheim/tesseract/releases")
                st.info("Then install: pip install pytesseract pillow")
                return None
            
            img = Image.open(uploaded_file)
            raw_text = pytesseract.image_to_string(img)

        elif file_extension == ".txt":
            raw_text = uploaded_file.read().decode("utf-8")

    except Exception as e:
        st.error(f"Error processing file: {e}")
        return None

    return {"raw_text": raw_text}

def clean_and_normalize_text(raw_text_data):
    """Cleans and standardizes the extracted text."""
    if not raw_text_data or not raw_text_data.get("raw_text"):
        return {"clean_text": ""}

    text = raw_text_data["raw_text"]
    
    # Define normalization rules
    normalization_map = {
        r'\bHb\b|\bHGB\b': 'Hemoglobin',
        r'\bGLU\b|Blood Sugar': 'Glucose',
        r'Total Cholesterol': 'Cholesterol',
        r'WBC Count': 'White Blood Cell Count'
    }
    
    for pattern, replacement in normalization_map.items():
        text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)

    # Remove extra spaces, headers, footers
    lines = text.split('\n')
    cleaned_lines = [
        line.strip() for line in lines
        if not re.match(r'^\s*Page \d+|\bDate\b:|\bReport Generated On\b', line, re.IGNORECASE) and line.strip()
    ]
    
    clean_text = ' '.join(cleaned_lines)
    clean_text = re.sub(r'\s+', ' ', clean_text)
    
    return {"clean_text": clean_text}

# --- 3️⃣: NLP Information Extraction Layer ---

def extract_parameters_with_ner(clean_text_data):
    """Uses Regex to extract test parameters. A true NLP model would be an enhancement."""
    text = clean_text_data.get("clean_text", "")
    
    # Define common medical test patterns and their normal ranges
    medical_tests = {
        "Hemoglobin": {"unit": "g/dl", "normal_range": (12, 16)},
        "HGB": {"unit": "g/dl", "normal_range": (12, 16)},
        "P.C.V": {"unit": "%", "normal_range": (36, 46)},
        "R.B.C": {"unit": "million/cu mm", "normal_range": (4.5, 5.5)},
        "W.B.C": {"unit": "cells/cu mm", "normal_range": (4000, 11000)},
        "Platelet Count": {"unit": "lacs/cu mm", "normal_range": (1.5, 4.5)},
        "Polymorphs": {"unit": "%", "normal_range": (40, 75)},
        "Lymphocytes": {"unit": "%", "normal_range": (20, 45)},
        "Eosinophils": {"unit": "%", "normal_range": (1, 6)},
        "Monocytes": {"unit": "%", "normal_range": (2, 10)},
        "SR": {"unit": "mm/Hr", "normal_range": (0, 20)},
        "ESR": {"unit": "mm/Hr", "normal_range": (0, 20)},
        "Blood Sugar": {"unit": "mg/dl", "normal_range": (70, 140)},
        "Random Blood Sugar": {"unit": "mg/dl", "normal_range": (70, 140)},
        "Serum Creatinine": {"unit": "mg/dl", "normal_range": (0.6, 1.2)},
        "Blood Urea": {"unit": "mg/dl", "normal_range": (7, 20)},
        "Serum Sodium": {"unit": "mmol/L", "normal_range": (135, 145)},
        "Serum Potassium": {"unit": "mmol/L", "normal_range": (3.5, 5.0)},
        "Serum Chlorides": {"unit": "mmol/L", "normal_range": (98, 107)},
        "Total Bilirubin": {"unit": "mg/dl", "normal_range": (0.3, 1.2)},
        "Conjugated Bilirubin": {"unit": "mg/dl", "normal_range": (0.1, 0.3)},
        "Alkaline Phosphatase": {"unit": "U/L", "normal_range": (44, 147)},
        "SGOT": {"unit": "U/L", "normal_range": (10, 40)},
        "SGPT": {"unit": "U/L", "normal_range": (10, 40)},
        "Total Serum Proteins": {"unit": "g/dl", "normal_range": (6.0, 8.3)},
        "Albumin": {"unit": "g/dl", "normal_range": (3.5, 5.0)},
        "PT": {"unit": "sec", "normal_range": (11, 13)},
        "INR": {"unit": "", "normal_range": (0.8, 1.2)},
        "APTT": {"unit": "sec", "normal_range": (25, 35)},
        "BT": {"unit": "min", "normal_range": (2, 7)},
        "CT": {"unit": "min", "normal_range": (2, 7)}
    }
    
    extracted_data = []
    
    # Look for patterns like "Test Name: Value unit" or "Test Name Value unit"
    for test_name, test_info in medical_tests.items():
        # Multiple patterns to catch different formats
        patterns = [
            rf"{re.escape(test_name)}\s*[:\s]\s*([\d\.]+)\s*{re.escape(test_info['unit'])}",
            rf"{re.escape(test_name)}\s+([\d\.]+)\s*{re.escape(test_info['unit'])}",
            rf"{re.escape(test_name)}\s*[:\s]\s*([\d\.]+)",
            rf"{re.escape(test_name)}\s+([\d\.]+)"
        ]
        
        for pattern in patterns:
            matches = re.finditer(pattern, text, re.IGNORECASE)
            for match in matches:
                try:
                    value = float(match.group(1))
                    extracted_data.append({
                        "test_name": test_name,
                        "value": value,
                        "unit": test_info["unit"],
                        "range_low": test_info["normal_range"][0],
                        "range_high": test_info["normal_range"][1]
                    })
                    break  # Found the test, move to next test
                except (ValueError, IndexError):
                    continue
    
    # Also look for specific patterns from your report
    specific_patterns = [
        (r"P\.C\.V\s+([\d\.]+)", "P.C.V", "%", (36, 46)),
        (r"R\.B\.C\s+([\d\.]+)", "R.B.C", "million/cu mm", (4.5, 5.5)),
        (r"W\.B\.C\s+([\d\.]+)", "W.B.C", "cells/cu mm", (4000, 11000)),
        (r"Platelet Count\s+([\d\.]+)", "Platelet Count", "lacs/cu mm", (1.5, 4.5)),
        (r"Polymorphs\s+([\d\.]+)%", "Polymorphs", "%", (40, 75)),
        (r"Lymphocytes\s+([\d\.]+)%", "Lymphocytes", "%", (20, 45)),
        (r"Eosinophils\s+([\d\.]+)%", "Eosinophils", "%", (1, 6)),
        (r"Monocytes\s+([\d\.]+)%", "Monocytes", "%", (2, 10)),
        (r"SR\s+([\d\.]+)mm", "ESR", "mm/Hr", (0, 20)),
        (r"Blood Sugar\s+([\d\.]+)", "Blood Sugar", "mg/dl", (70, 140)),
        (r"Serum Creatinine\s+([\d\.]+)", "Serum Creatinine", "mg/dl", (0.6, 1.2)),
        (r"Blood Urea\s+([\d\.]+)", "Blood Urea", "mg/dl", (7, 20)),
        (r"Serum Sodium\s+([\d\.]+)", "Serum Sodium", "mmol/L", (135, 145)),
        (r"Serum Potassium\s+([\d\.]+)", "Serum Potassium", "mmol/L", (3.5, 5.0)),
        (r"Serum Chlorides\s+([\d\.]+)", "Serum Chlorides", "mmol/L", (98, 107)),
        (r"Total Bilirubin\s+([\d\.]+)", "Total Bilirubin", "mg/dl", (0.3, 1.2)),
        (r"Conjugated Bilirubin\s+([\d\.]+)", "Conjugated Bilirubin", "mg/dl", (0.1, 0.3)),
        (r"Alkaline Phosphatase\s+([\d\.]+)", "Alkaline Phosphatase", "U/L", (44, 147)),
        (r"SGOT\s+([\d\.]+)", "SGOT", "U/L", (10, 40)),
        (r"SGPT\s+([\d\.]+)", "SGPT", "U/L", (10, 40)),
        (r"Total Serum Proteins\s+([\d\.]+)", "Total Serum Proteins", "g/dl", (6.0, 8.3)),
        (r"Albumin\s+([\d\.]+)", "Albumin", "g/dl", (3.5, 5.0)),
        (r"PT\s+([\d\.]+)", "PT", "sec", (11, 13)),
        (r"INR\s+([\d\.]+)", "INR", "", (0.8, 1.2)),
        (r"APTT\s+([\d\.]+)", "APTT", "sec", (25, 35)),
        (r"BT\s+([\d\.]+)", "BT", "min", (2, 7)),
        (r"CT\s+([\d\.]+)", "CT", "min", (2, 7))
    ]
    
    for pattern, test_name, unit, normal_range in specific_patterns:
        matches = re.finditer(pattern, text, re.IGNORECASE)
        for match in matches:
            try:
                value = float(match.group(1))
                # Check if we already have this test
                if not any(item["test_name"] == test_name for item in extracted_data):
                    extracted_data.append({
                        "test_name": test_name,
                        "value": value,
                        "unit": unit,
                        "range_low": normal_range[0],
                        "range_high": normal_range[1]
                    })
            except (ValueError, IndexError):
                continue
            
    return extracted_data

def classify_tests(extracted_params):
    """Classifies tests into 'regular' or 'periodic'."""
    regular_keywords = ["glucose", "blood pressure", "heart rate", "oxygen", "bmi"]
    for param in extracted_params:
        if any(keyword in param["test_name"].lower() for keyword in regular_keywords):
            param["category"] = "regular"
        else:
            param["category"] = "periodic"
    return extracted_params

# --- 4️⃣: Health Status Computation Layer ---

def compute_health_status(extracted_params):
    """Compares values with normal ranges to determine status."""
    for param in extracted_params:
        value, low, high = param["value"], param["range_low"], param["range_high"]
        if value < low:
            param["status"], param["color"] = "Low", "blue"
        elif value > high:
            param["status"], param["color"] = "High", "red"
        else:
            param["status"], param["color"] = "Normal", "green"
    return extracted_params

# --- 5️⃣: Medical Explanation Generation Layer (Corrected & Improved) ---

KNOWLEDGE_DICTIONARY = {
    "Hemoglobin": {
        "low": "Low hemoglobin indicates anemia, which can cause fatigue and weakness. Eat iron-rich foods like spinach, lentils, and lean meats.",
        "normal": "Your hemoglobin level is healthy, indicating good oxygen-carrying capacity.",
        "high": "High hemoglobin may indicate dehydration or other conditions. Consult your doctor for evaluation."
    },
    "P.C.V": {
        "low": "Low packed cell volume suggests anemia. Ensure adequate iron and vitamin B12 intake.",
        "normal": "Your packed cell volume is within normal range, indicating healthy blood composition.",
        "high": "High packed cell volume may indicate dehydration or other blood disorders."
    },
    "R.B.C": {
        "low": "Low red blood cell count indicates anemia. Focus on iron-rich diet and consult your doctor.",
        "normal": "Your red blood cell count is healthy, ensuring proper oxygen transport.",
        "high": "High red blood cell count may indicate dehydration or blood disorders."
    },
    "W.B.C": {
        "low": "Low white blood cell count may indicate weakened immune system. Avoid infections and consult your doctor.",
        "normal": "Your white blood cell count is healthy, indicating good immune function.",
        "high": "High white blood cell count may indicate infection or inflammation. Monitor for symptoms."
    },
    "Platelet Count": {
        "low": "Low platelet count may cause bleeding issues. Avoid injury and consult your doctor immediately.",
        "normal": "Your platelet count is healthy, ensuring proper blood clotting.",
        "high": "High platelet count may increase clotting risk. Monitor and consult your doctor."
    },
    "Serum Creatinine": {
        "low": "Low creatinine may indicate reduced muscle mass or kidney issues. Consult your doctor.",
        "normal": "Your kidney function appears healthy based on creatinine levels.",
        "high": "High creatinine indicates reduced kidney function. Follow your doctor's advice for kidney care."
    },
    "Blood Urea": {
        "low": "Low blood urea is generally not concerning and may indicate good hydration.",
        "normal": "Your blood urea level is healthy, indicating good kidney function.",
        "high": "High blood urea may indicate kidney dysfunction or dehydration. Increase fluid intake and consult your doctor."
    },
    "Serum Sodium": {
        "low": "Low sodium may cause weakness and confusion. Increase salt intake moderately and consult your doctor.",
        "normal": "Your sodium level is healthy, maintaining proper fluid balance.",
        "high": "High sodium may indicate dehydration. Increase fluid intake and reduce salt consumption."
    },
    "Serum Potassium": {
        "low": "Low potassium may cause muscle weakness and irregular heartbeat. Eat potassium-rich foods like bananas.",
        "normal": "Your potassium level is healthy, supporting proper muscle and heart function.",
        "high": "High potassium can be dangerous for heart function. Consult your doctor immediately."
    },
    "Total Bilirubin": {
        "low": "Low bilirubin is generally not concerning.",
        "normal": "Your bilirubin level is healthy, indicating good liver function.",
        "high": "High bilirubin may indicate liver or bile duct issues. Consult your doctor for evaluation."
    },
    "SGOT": {
        "low": "Low SGOT is generally not concerning.",
        "normal": "Your liver enzyme levels are healthy.",
        "high": "High SGOT may indicate liver damage or heart issues. Consult your doctor."
    },
    "SGPT": {
        "low": "Low SGPT is generally not concerning.",
        "normal": "Your liver enzyme levels are healthy.",
        "high": "High SGPT may indicate liver damage. Avoid alcohol and consult your doctor."
    },
    "Albumin": {
        "low": "Low albumin may indicate malnutrition or liver/kidney issues. Ensure adequate protein intake.",
        "normal": "Your albumin level is healthy, indicating good nutritional status.",
        "high": "High albumin may indicate dehydration. Increase fluid intake."
    },
    "INR": {
        "low": "Low INR may increase bleeding risk. Consult your doctor about blood thinning medication.",
        "normal": "Your blood clotting time is within normal range.",
        "high": "High INR increases bleeding risk. Avoid injury and consult your doctor immediately."
    }
}

def generate_explanations(analyzed_params, use_llm=False, api_key=None):
    """Generates simple explanations for each test result, with an updated OpenAI call."""
    client = openai.OpenAI(api_key=api_key) if use_llm and api_key else None

    for param in analyzed_params:
        test_name_key = next((k for k in KNOWLEDGE_DICTIONARY if k.lower() in param["test_name"].lower()), None)
        status_key = param["status"].lower()
        
        if test_name_key and status_key in KNOWLEDGE_DICTIONARY[test_name_key]:
            param["explanation"] = KNOWLEDGE_DICTIONARY[test_name_key][status_key]
        elif client:
            try:
                prompt = (
                    f"Explain this medical test result to a patient in simple, reassuring terms (under 50 words).\n"
                    f"Test: {param['test_name']}, Value: {param['value']} {param.get('unit', '')}, "
                    f"Normal Range: {param['range_low']}-{param['range_high']}, Status: {param['status']}"
                )
                response = client.chat.completions.create(
                    model="gpt-3.5-turbo",
                    messages=[
                        {"role": "system", "content": "You are a helpful medical assistant."},
                        {"role": "user", "content": prompt}
                    ]
                )
                param["explanation"] = response.choices[0].message.content.strip()
            except Exception as e:
                param["explanation"] = "Could not generate AI explanation. Using default message."
                st.warning(f"OpenAI API call failed: {e}")
        else:
            param["explanation"] = f"Your {param['test_name']} level is {param['status']}. Please consult your doctor."
            
    return analyzed_params

# --- 8️⃣: Health Score Calculation ---

def calculate_health_score(analyzed_params):
    """Calculates a health score based on the number of normal parameters."""
    if not analyzed_params:
        return 0, "⚪"
        
    normal_count = sum(1 for p in analyzed_params if p["status"] == "Normal")
    score = (normal_count / len(analyzed_params)) * 100
    
    if score >= 90: emoji = "🟢"
    elif 70 <= score < 90: emoji = "🟡"
    else: emoji = "🔴"
    
    return int(score), emoji

# --- 1️⃣0️⃣: Storage and Security (Corrected & Improved) ---

def setup_database():
    """Initializes the SQLite database connection and table."""
    conn = sqlite3.connect(DB_FILE)
    conn.execute('''
        CREATE TABLE IF NOT EXISTS patient_reports (
            id INTEGER PRIMARY KEY, patient_name TEXT,
            report_date DATE, report_data BLOB
        )
    ''')
    conn.close()

def save_report_to_db(patient_name, report_date, report_data):
    """Encrypts and saves a report to the SQLite database."""
    conn = sqlite3.connect(DB_FILE)
    encrypted_data = cipher_suite.encrypt(json.dumps(report_data).encode())
    conn.execute("INSERT INTO patient_reports (patient_name, report_date, report_data) VALUES (?, ?, ?)",
                 (patient_name, report_date, encrypted_data))
    conn.commit()
    conn.close()

def load_reports_from_db(patient_name):
    """Loads and decrypts the last 5 reports for a specific patient."""
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.execute("SELECT report_date, report_data FROM patient_reports WHERE patient_name = ? ORDER BY report_date DESC LIMIT 5", (patient_name,))
    reports = []
    for row in cursor.fetchall():
        try:
            decrypted_data = cipher_suite.decrypt(row[1])
            reports.append({"date": row[0], "data": json.loads(decrypted_data.decode())})
        except Exception as e:
            st.warning(f"Could not decrypt an old report. The encryption key may have changed. {e}")
            continue
    conn.close()
    return reports

# --- 6️⃣ & 7️⃣: Comparison and Visualization Layer (Corrected & Optimized) ---

def display_dashboard(final_output, historical_data):
    """Renders the main dashboard with score, charts, and tables."""
    st.header(f"🩺 Health Report for {final_output['patient_name']}")
    st.markdown(f"**Report Date:** {final_output['report_date']}")
    
    score, emoji = final_output["health_score"]
    st.metric(label="Overall Health Score", value=f"{score}%", delta=f"{emoji} {'Excellent' if score >= 90 else 'Average' if score >= 70 else 'Needs Attention'}")

    regular_tests = [t for t in final_output["tests"] if t['category'] == 'regular']
    periodic_tests = [t for t in final_output["tests"] if t['category'] == 'periodic']

    if regular_tests:
        st.markdown("---")
        st.subheader("📈 Regular Test Trends")
        # --- Efficiently process historical data ONCE ---
        history_map = {}
        for report in historical_data:
            for test in report['data']['tests']:
                name = test['test_name']
                if name not in history_map: history_map[name] = []
                history_map[name].append({"date": report['date'], "value": test['value']})

        for test in regular_tests:
            test_name = test['test_name']
            all_readings = [{"date": final_output['report_date'], "value": test['value']}]
            if test_name in history_map:
                all_readings.extend(history_map[test_name])

            trend_df = pd.DataFrame(all_readings).sort_values('date', ascending=False).reset_index(drop=True)
            
            col1, col2 = st.columns([1, 2])
            with col1:
                st.markdown(f"**{test_name}**")
                st.markdown(f"<p style='color:{test['color']}; font-size: 24px;'>{test['value']} {test.get('unit', '')}</p>", unsafe_allow_html=True)
                st.caption(f"Status: {test['status']}")

            with col2:
                if len(trend_df) > 1:
                    fig = px.line(trend_df.sort_values('date'), x='date', y='value', title=f'{test_name} Trend', markers=True)
                    st.plotly_chart(fig, use_container_width=True)
                    
                    # --- Improved and more flexible trend text ---
                    latest_val, prev_val = trend_df['value'].iloc[0], trend_df['value'].iloc[1]
                    if latest_val > prev_val:
                        trend_text = f"This is higher than your last reading of {prev_val}."
                    elif latest_val < prev_val:
                        trend_text = f"This is lower than your last reading of {prev_val}."
                    else:
                        trend_text = "This has remained stable since your last reading."
                    st.info(trend_text)
                else:
                    st.write("This is your first reading for this test.")
            
            with st.expander("What does this mean?"):
                st.write(test['explanation'])

    if periodic_tests:
        st.markdown("---")
        st.subheader("🔬 Periodic Test Results")
        df_data = [
            [
                f'{"⚠️" if t["status"] != "Normal" else "✅"} {t["test_name"]}',
                f"{t['value']} {t.get('unit', '')}",
                f"{t['range_low']} - {t['range_high']}",
                t['status']
            ] for t in periodic_tests
        ]
        st.table(pd.DataFrame(df_data, columns=["Test Name", "Your Value", "Normal Range", "Status"]))
        for test in periodic_tests:
            with st.expander(f"Explanation for {test['test_name']}"):
                st.write(test['explanation'])

# --- 1️⃣1️⃣: System Flow (Main App Logic) ---

def main():
    st.set_page_config(page_title="AI Report Simplifier", layout="wide")
    st.title("🩺 AI Medical Report Simplifier")
    
    setup_database()

    with st.sidebar:
        st.header("Upload Report")
        patient_name = st.text_input("Enter Patient Name", "Akhil Reddy")
        input_type = st.radio("Choose Input Type", ["File Upload", "Plain Text"])
        
        uploaded_file, input_text = None, ""
        if input_type == "File Upload":
            if OCR_AVAILABLE:
                uploaded_file = st.file_uploader("Upload a report (PDF, JPG, PNG)", type=["pdf", "jpg", "jpeg", "png"])
            else:
                uploaded_file = st.file_uploader("Upload a report (TXT only - OCR not available)", type=["txt"])
                st.warning("⚠️ OCR functionality is not available. Only text files (.txt) are supported for file upload.")
                st.info("To enable PDF and image processing, please install Tesseract OCR and required packages.")
        else:
            input_text = st.text_area("Paste report text here", height=200)

        st.markdown("---")
        use_llm = st.checkbox("Use Advanced AI for Explanations (GPT-4)")
        api_key = st.text_input("Enter OpenAI API Key", type="password") if use_llm else None
        
        analyze_button = st.button("Analyze Report", type="primary")

    if analyze_button and (uploaded_file or input_text):
        with st.spinner("Analyzing report... This may take a moment."):
            raw_text_data = extract_text_from_source(uploaded_file) if uploaded_file else {"raw_text": input_text}
            if not raw_text_data or not raw_text_data.get("raw_text", "").strip():
                st.error("Could not extract text. Please check the file or text content.")
                return

            clean_text_data = clean_and_normalize_text(raw_text_data)
            extracted_params = extract_parameters_with_ner(clean_text_data)
            
            if not extracted_params:
                st.error("No valid medical parameters were found. The report format might be unsupported.")
                with st.expander("View Extracted Text for Debugging"):
                    st.text(clean_text_data.get("clean_text"))
                return

            # Main processing pipeline
            classified_params = classify_tests(extracted_params)
            analyzed_params = compute_health_status(classified_params)
            final_params = generate_explanations(analyzed_params, use_llm, api_key)
            score, emoji = calculate_health_score(final_params)
            
            report_date = datetime.now().strftime("%Y-%m-%d")
            final_output = {
                "patient_name": patient_name,
                "report_date": report_date,
                "health_score": (score, emoji),
                "tests": final_params
            }
            
            save_report_to_db(patient_name, report_date, final_output)
            historical_reports = load_reports_from_db(patient_name)
            
        display_dashboard(final_output, historical_reports)
    else:
        st.info("Please provide a report and click 'Analyze Report' to begin.")

if __name__ == "__main__":
    main()