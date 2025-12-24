import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class SimplifiedReportPage extends StatefulWidget {
  const SimplifiedReportPage({super.key});

  @override
  State<SimplifiedReportPage> createState() => _SimplifiedReportPageState();
}

class _SimplifiedReportPageState extends State<SimplifiedReportPage> {
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _textInputController = TextEditingController();
  
  bool _isLoading = false;
  Map<String, dynamic>? _reportData;
  String? _errorMessage;
  
  // API Configuration
  static const String _baseUrl = 'http://127.0.0.1:8000';
  
  @override
  void dispose() {
    _patientNameController.dispose();
    _textInputController.dispose();
    super.dispose();
  }

  Future<void> _analyzeReportFromBytes(Uint8List bytes, String filename) async {
    if (_patientNameController.text.trim().isEmpty) {
      _showError('Please enter patient name');
      return;
    }

    print('Starting file upload from bytes...');
    print('File name: $filename');
    print('File size: ${bytes.length} bytes');
    print('Patient name: ${_patientNameController.text.trim()}');

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/analyze-report'),
      );
      
      request.fields['patient_name'] = _patientNameController.text.trim();
      
      // Add the file bytes to the request
      var multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      );
      request.files.add(multipartFile);
      
      print('Sending request to: $_baseUrl/analyze-report');
      
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      
      print('Response status: ${response.statusCode}');
      print('Response body: $responseBody');
      
      if (response.statusCode == 200) {
        setState(() {
          _reportData = json.decode(responseBody);
          _isLoading = false;
        });
        print('File upload successful!');
      } else {
        setState(() {
          try {
            var errorData = json.decode(responseBody);
            _errorMessage = 'Error: ${errorData['detail']}';
          } catch (e) {
            _errorMessage = 'Error: ${response.statusCode} - $responseBody';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload file: ${e.toString()}';
        _isLoading = false;
      });
      print('File upload error: $e');
    }
  }

  Future<void> _analyzeReportFromFile(File file) async {
    if (_patientNameController.text.trim().isEmpty) {
      _showError('Please enter patient name');
      return;
    }

    print('Starting file upload...');
    print('File path: ${file.path}');
    print('File exists: ${file.existsSync()}');
    print('File size: ${file.lengthSync()} bytes');
    print('Patient name: ${_patientNameController.text.trim()}');

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/analyze-report'),
      );
      
      request.fields['patient_name'] = _patientNameController.text.trim();
      
      // Add the file to the request
      var multipartFile = await http.MultipartFile.fromPath('file', file.path);
      request.files.add(multipartFile);
      
      print('Sending request to: $_baseUrl/analyze-report');
      
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      
      print('Response status: ${response.statusCode}');
      print('Response body: $responseBody');
      
      if (response.statusCode == 200) {
        setState(() {
          _reportData = json.decode(responseBody);
          _isLoading = false;
        });
        print('File upload successful!');
      } else {
        setState(() {
          try {
            var errorData = json.decode(responseBody);
            _errorMessage = 'Error: ${errorData['detail']}';
          } catch (e) {
            _errorMessage = 'Error: ${response.statusCode} - $responseBody';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload file: ${e.toString()}';
        _isLoading = false;
      });
      print('File upload error: $e');
    }
  }

  Future<void> _analyzeReportFromText() async {
    if (_patientNameController.text.trim().isEmpty) {
      _showError('Please enter patient name');
      return;
    }
    
    if (_textInputController.text.trim().isEmpty) {
      _showError('Please enter report text');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _reportData = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze-report'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'patient_name': _patientNameController.text.trim(),
          'text_input': _textInputController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _reportData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error: ${json.decode(response.body)['detail']}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to analyze text: ${e.toString()}';
        _isLoading = false;
      });
      print('Text analysis error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        // Show a loading indicator
        setState(() {
          _isLoading = true;
          _errorMessage = null;
          _reportData = null;
        });
        
        if (kIsWeb) {
          // For web platform, read bytes
          final bytes = await image.readAsBytes();
          await _analyzeReportFromBytes(bytes, image.name);
        } else {
          // For mobile platforms, use file path
          await _analyzeReportFromFile(File(image.path));
        }
      }
    } catch (e) {
      _showError('Error picking image: ${e.toString()}');
      print('Image picker error: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'txt'],
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        
        // Show a loading indicator
        setState(() {
          _isLoading = true;
          _errorMessage = null;
          _reportData = null;
        });
        
        // Handle different platforms
        if (kIsWeb) {
          // For web platform, use bytes
          if (file.bytes != null) {
            print('Selected file: ${file.name}');
            print('File size: ${file.bytes!.length} bytes');
            await _analyzeReportFromBytes(file.bytes!, file.name);
          } else {
            _showError('File bytes are null');
          }
        } else {
          // For mobile platforms, use path
          String? filePath = file.path;
          if (filePath != null) {
            File fileObj = File(filePath);
            print('Selected file: ${fileObj.path}');
            print('File exists: ${fileObj.existsSync()}');
            print('File size: ${fileObj.lengthSync()} bytes');
            await _analyzeReportFromFile(fileObj);
          } else {
            _showError('File path is null');
          }
        }
      } else {
        _showError('No file selected');
      }
    } catch (e) {
      _showError('Error selecting file: ${e.toString()}');
      print('File picker error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'AI Report Analysis',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF1E40AF),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Analyzing your report...',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            )
          : _reportData != null
              ? _buildReportDisplay()
              : _buildInputForm(),
    );
  }

  Widget _buildInputForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E40AF).withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.medical_services,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 12),
                const Text(
                  'AI Medical Report Analyzer',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload your medical report and get a simplified, easy-to-understand analysis',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Patient Name Input
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Patient Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _patientNameController,
                  decoration: InputDecoration(
                    labelText: 'Patient Name',
                    hintText: 'Enter patient name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1E40AF)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // File Upload Options
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upload Report',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                
                // File Upload Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Text Input Option
                const Text(
                  'Or paste report text:',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _textInputController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Paste your medical report text here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1E40AF)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _analyzeReportFromText,
                    icon: const Icon(Icons.analytics),
                    label: const Text('Analyze Text'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReportDisplay() {
    final healthScore = _reportData!['health_score'];
    final tests = _reportData!['tests'] as List<dynamic>;
    final summary = _reportData!['summary'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Patient Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report for ${_reportData!['patient_name']}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Report Date: ${_reportData!['report_date']}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Health Score Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Overall Health Score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${healthScore['score']}%',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: healthScore['score'] >= 90 
                        ? Colors.green 
                        : healthScore['score'] >= 70 
                            ? Colors.orange 
                            : Colors.red,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  healthScore['status'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Total Tests', '${summary['total_tests']}'),
                    _buildSummaryItem('Normal', '${summary['normal_tests']}'),
                    _buildSummaryItem('Abnormal', '${summary['abnormal_tests']}'),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Test Results
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Test Results',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                ...tests.map((test) => _buildTestItem(test)),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _reportData = null;
                      _errorMessage = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Analyze Another Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Color(0xFF1E40AF),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildTestItem(Map<String, dynamic> test) {
    Color statusColor;
    IconData statusIcon;
    
    switch (test['status']) {
      case 'Normal':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'High':
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        break;
      case 'Low':
        statusColor = Colors.blue;
        statusIcon = Icons.info;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  test['test_name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  test['status'],
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Value: ${test['value']} ${test['unit']}',
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              color: Color(0xFF374151),
            ),
          ),
          Text(
            'Normal Range: ${test['range_low']} - ${test['range_high']} ${test['unit']}',
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              test['explanation'],
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
