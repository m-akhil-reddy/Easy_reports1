import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class ReportAnalysisService {
  static const String baseUrl = 'http://localhost:5000';
  final Dio _dio = Dio();

  ReportAnalysisService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  /// Check if the API server is running
  Future<bool> checkServerHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get supported file formats
  Future<Map<String, dynamic>> getSupportedFormats() async {
    try {
      final response = await _dio.get('/supported-formats');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get supported formats: $e');
    }
  }

  /// Analyze a medical report
  Future<Map<String, dynamic>> analyzeReport({
    required PlatformFile file,
    required String patientName,
    bool useLLM = false,
    String? apiKey,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        ),
        'patient_name': patientName,
        'use_llm': useLLM.toString(),
        if (apiKey != null) 'api_key': apiKey,
      });

      final response = await _dio.post(
        '/analyze-report',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Analysis failed: ${response.data['error']}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          throw Exception('Request timed out. The analysis is taking longer than expected.');
        } else if (e.type == DioExceptionType.connectionError) {
          throw Exception('Cannot connect to the analysis server. Please make sure the Python server is running.');
        }
      }
      throw Exception('Failed to analyze report: $e');
    }
  }

  /// Get patient history
  Future<Map<String, dynamic>> getPatientHistory(String patientName) async {
    try {
      final response = await _dio.get('/get-patient-history/$patientName');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get patient history: $e');
    }
  }
}
