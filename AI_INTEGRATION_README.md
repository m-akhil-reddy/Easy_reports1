# Medical Report AI Integration

This integration connects your Flutter app with the Python AI model for medical report analysis using FastAPI.

## 🚀 Quick Start

### 1. Start the Python AI Server

**Option A: Using the batch file (Windows)**
```bash
# Double-click start_server.bat or run in command prompt
start_server.bat
```

**Option B: Using Python directly**
```bash
# Navigate to the NxtWava directory
cd C:\Users\swecha\Desktop\NxtWava

# Install dependencies
pip install -r requirements.txt

# Start the server
python start_server.py
```

### 2. Run the Flutter App

```bash
# Navigate to your Flutter project
cd C:\Users\swecha\Desktop\NxtWava\EZ_reports

# Get dependencies
flutter pub get

# Run the app
flutter run
```

## 📱 How to Use

1. **Open the Flutter app** and navigate to the home page
2. **Tap the "Scan Report" button** (green floating action button)
3. **Enter patient name** in the input field
4. **Upload a report** using one of these methods:
   - **Upload File**: Select PDF, JPG, PNG, or TXT files
   - **Take Photo**: Use camera to capture report
   - **Paste Text**: Manually enter report text
5. **Tap "Analyze"** to process the report
6. **View the simplified results** with:
   - Overall health score
   - Individual test results with explanations
   - Normal ranges and status indicators

## 🔧 Technical Details

### API Endpoints

- **POST** `/analyze-report` - Analyze medical reports
- **GET** `/patient-history/{patient_name}` - Get patient history
- **GET** `/health` - Health check endpoint
- **GET** `/docs` - API documentation (Swagger UI)

### Supported File Formats

- **PDF**: Both text-based and scanned PDFs (OCR required for scanned)
- **Images**: JPG, JPEG, PNG (OCR required)
- **Text**: Plain text files (.txt)

### AI Processing Pipeline

1. **Text Extraction**: Extract text from uploaded files
2. **Text Cleaning**: Normalize and clean extracted text
3. **Parameter Extraction**: Identify medical test parameters using regex patterns
4. **Health Analysis**: Compare values with normal ranges
5. **Explanation Generation**: Create simple explanations for each result
6. **Score Calculation**: Calculate overall health score

## 🛠️ Troubleshooting

### Server Won't Start

1. **Check Python installation**:
   ```bash
   python --version
   ```

2. **Install missing dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Check port availability**: Ensure port 8000 is not in use

### OCR Not Working

1. **Install Tesseract OCR**:
   - Download from: https://github.com/UB-Mannheim/tesseract/releases
   - Add to system PATH

2. **Install OCR Python packages**:
   ```bash
   pip install pytesseract pillow PyMuPDF
   ```

### Flutter App Can't Connect

1. **Check server is running**: Visit http://127.0.0.1:8000/health
2. **Check network permissions**: Ensure Flutter app can access localhost
3. **Verify API URL**: Check `_baseUrl` in `simplified_report_page.dart`

## 📁 File Structure

```
NxtWava/
├── Aimodal.py                 # Original AI model
├── fastapi_server.py          # FastAPI server
├── start_server.py            # Server startup script
├── start_server.bat           # Windows batch file
├── requirements.txt           # Python dependencies
├── patient_reports.db         # SQLite database
└── EZ_reports/
    └── lib/
        ├── simplified_report_page.dart  # New Flutter page
        └── home.dart                    # Updated home page
```

## 🔒 Security Notes

- The server runs on localhost (127.0.0.1) for security
- Patient data is encrypted in the SQLite database
- No data is sent to external servers (except optional OpenAI API)
- CORS is enabled for local development

## 🎯 Features

### For Patients
- ✅ Simple, easy-to-understand explanations
- ✅ Visual health score with color coding
- ✅ Normal range comparisons
- ✅ Historical trend tracking
- ✅ Multiple input methods (file, photo, text)

### For Developers
- ✅ RESTful API with FastAPI
- ✅ Automatic API documentation
- ✅ Error handling and validation
- ✅ Modular, extensible code
- ✅ Local database storage

## 📞 Support

If you encounter any issues:

1. Check the server logs for error messages
2. Verify all dependencies are installed
3. Ensure the Flutter app has proper permissions
4. Check the API documentation at http://127.0.0.1:8000/docs

## 🔄 Updates

To update the integration:

1. Pull latest changes from git
2. Update Python dependencies: `pip install -r requirements.txt`
3. Update Flutter dependencies: `flutter pub get`
4. Restart both server and app
