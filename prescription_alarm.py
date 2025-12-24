import re
from datetime import datetime, timedelta
from Aimodal import extract_text_from_source, clean_and_normalize_text

def extract_prescription_date(text):
    """
    Extracts the date from the report text.
    Looks for patterns like 'Date: YYYY-MM-DD' or 'Report Date: DD/MM/YYYY'.
    """
    date_patterns = [
        r"Date[:\s]+(\d{4}-\d{2}-\d{2})",
        r"Report Date[:\s]+(\d{2}/\d{2}/\d{4})"
    ]
    for pattern in date_patterns:
        match = re.search(pattern, text)
        if match:
            date_str = match.group(1)
            try:
                if "-" in date_str:
                    return datetime.strptime(date_str, "%Y-%m-%d")
                elif "/" in date_str:
                    return datetime.strptime(date_str, "%d/%m/%Y")
            except ValueError:
                continue
    # fallback: use today if no date found
    return datetime.now()

def extract_prescriptions(text):
    """
    Extract medicines, dosage, and frequency from report text.
    """
    prescriptions = []
    # Example pattern: "Paracetamol 500mg 3 times a day"
    pattern = r"([A-Za-z\s]+)\s+(\d+mg|\d+ml)\s+([\d\s\w]+)"
    matches = re.finditer(pattern, text)
    for match in matches:
        prescriptions.append({
            "medicine": match.group(1).strip(),
            "dosage": match.group(2).strip(),
            "frequency": match.group(3).strip()
        })
    return prescriptions

def schedule_alarms(prescriptions, report_date):
    """
    Schedules alarms based on prescription frequency.
    """
    alarms = []
    for p in prescriptions:
        # Simple example: "3 times a day" => every 8 hours
        freq_match = re.search(r'(\d+)', p['frequency'])
        if freq_match:
            times_per_day = int(freq_match.group(1))
            interval_hours = 24 / times_per_day
            alarms.append({
                "medicine": p['medicine'],
                "next_dose": report_date + timedelta(hours=interval_hours)
            })
    return alarms

def process_report(uploaded_file=None, input_text=""):
    """
    Main function: takes a file or plain text report,
    extracts prescription info, report date, and returns alarms.
    """
    raw_text_data = None
    if uploaded_file:
        raw_text_data = extract_text_from_source(uploaded_file)
    elif input_text:
        raw_text_data = {"raw_text": input_text}

    if not raw_text_data or not raw_text_data.get("raw_text", "").strip():
        return None, None, None

    clean_text_data = clean_and_normalize_text(raw_text_data)
    clean_text = clean_text_data.get("clean_text", "")

    report_date = extract_prescription_date(clean_text)
    prescriptions = extract_prescriptions(clean_text)
    alarms = schedule_alarms(prescriptions, report_date)

    return report_date, prescriptions, alarms

# --- Example usage ---
if __name__ == "__main__":
    # Example: Replace this with uploaded file or text
    report_text = """
    Patient Name: John Doe
    Report Date: 2025-10-12
    Paracetamol 500mg 3 times a day
    Amoxicillin 250mg 2 times a day
    """
    date, prescriptions, alarms = process_report(input_text=report_text)

    print("Report Date:", date)
    print("Prescriptions:", prescriptions)
    print("Scheduled Alarms:", alarms)
