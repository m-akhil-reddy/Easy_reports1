# Easy Reports

A comprehensive healthcare application for analyzing and visualizing medical reports using AI-powered text extraction, NLP, and health status computation. The system consists of a FastAPI backend for processing reports and a Flutter mobile app for user interaction.

## Features

- **AI-Powered Report Analysis**: Extracts and analyzes medical parameters from PDFs, images, and text files using OCR and NLP.
- **Health Status Computation**: Calculates health scores and generates medical explanations.
- **Data Visualization**: Provides comparison and visualization of health data.
- **Secure Storage**: Stores reports securely with encryption.
- **Cross-Platform Mobile App**: Flutter-based app for easy access on Android, iOS, and web.
- **Real-time Processing**: FastAPI server for efficient backend processing.

## Tech Stack

### Backend (Python)
- **FastAPI**: High-performance web framework for API development
- **OpenAI**: AI-powered NLP and text generation
- **PyTesseract**: OCR for text extraction from images
- **PyMuPDF**: PDF processing
- **Pandas & Plotly**: Data analysis and visualization
- **Cryptography**: Secure data handling

### Frontend (Flutter)
- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language
- **Supabase**: Backend-as-a-Service for data management

## Installation

### Prerequisites
- Python 3.8+
- Flutter SDK
- Tesseract OCR (for text extraction)
- Supabase account (for data storage)

### Backend Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/m-akhil-reddy/Easy_reports1.git
   cd Easy_reports1
   ```

2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Install Tesseract OCR:
   - Windows: Download from [GitHub releases](https://github.com/UB-Mannheim/tesseract/wiki)
   - Or run: `python install_tesseract.py`

4. Set up environment variables:
   - Create a `.env` file with your OpenAI API key and other configurations
   - Refer to `get_api_key.md` for API setup

5. Run the FastAPI server:
   ```bash
   python start_server.py
   ```
   Or directly:
   ```bash
   uvicorn fastapi_server:app --reload
   ```

### Frontend Setup

1. Navigate to the Flutter app directory:
   ```bash
   cd EZ_reports
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Set up Supabase:
   - Configure your Supabase project
   - Update connection details in the app

4. Run the Flutter app:
   ```bash
   flutter run
   ```

## Usage

### Backend API

The FastAPI server provides endpoints for:
- `/upload-report`: Upload and process medical reports
- `/get-reports`: Retrieve stored reports
- `/analyze-report`: Get AI analysis of reports

### Mobile App

The Flutter app allows users to:
- Upload medical reports
- View analyzed health data
- Track health trends over time
- Receive notifications and alarms

## Project Structure

```
Easy_reports1/
├── Aimodal.py                 # Core AI model for report analysis
├── fastapi_server.py         # FastAPI backend server
├── prescription_alarm.py      # Alarm system for prescriptions
├── debug_text_extraction.py   # Debugging utilities
├── requirements.txt           # Python dependencies
├── setup_env.py              # Environment setup script
├── start_server.py          # Server startup script
├── EZ_reports/               # Flutter mobile app
│   ├── lib/                  # Dart source code
│   ├── android/              # Android-specific files
│   ├── ios/                  # iOS-specific files
│   └── pubspec.yaml          # Flutter dependencies
└── README.md                 # This file
```

## AI Model Workflow (Aimodal.py)

The AI model processes medical reports through several layers:

1. **Input and Data Extraction Layer**: Extracts raw text from PDFs, images, or plain text files using OCR and PDF parsing.
2. **NLP Info Extraction Layer**: Uses Named Entity Recognition (NER) to identify medical parameters and test results.
3. **Health Status Computation Layer**: Analyzes extracted data to determine health status indicators.
4. **Medical Explanation Generation Layer**: Generates human-readable explanations of health data.
5. **Health Score Calculation**: Computes overall health scores based on various parameters.
6. **Storage and Security Layer**: Securely stores processed data with encryption.
7. **Comparison and Visualization Layer**: Provides data comparison and visualization capabilities.
8. **System Flow (Main App Logic)**: Orchestrates the entire analysis pipeline.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For questions or support, please open an issue on GitHub.
