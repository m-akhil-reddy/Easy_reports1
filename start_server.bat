@echo off
echo Starting Medical Report AI Server...
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python is not installed or not in PATH
    echo Please install Python from https://python.org
    pause
    exit /b 1
)

REM Check if virtual environment exists
if exist "venv\Scripts\activate.bat" (
    echo Activating virtual environment...
    call venv\Scripts\activate.bat
) else (
    echo Warning: Virtual environment not found
    echo It's recommended to use a virtual environment
    echo.
)

REM Install/update dependencies
echo Installing/updating dependencies...
pip install -r requirements.txt

REM Start the server
echo.
echo Starting FastAPI server...
echo Server will be available at: http://127.0.0.1:8000
echo API documentation: http://127.0.0.1:8000/docs
echo Press Ctrl+C to stop the server
echo.

python start_server.py

pause
