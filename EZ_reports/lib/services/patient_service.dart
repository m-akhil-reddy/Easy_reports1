import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient_model.dart';
import 'auth_service.dart';

class PatientService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get all patients (for admin/staff use)
  static Future<List<Patient>> getAllPatients() async {
    try {
      final response = await _client
          .from('patients')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((patient) => Patient.fromMap(patient))
          .toList();
    } catch (e) {
      print('Error fetching patients: $e');
      return [];
    }
  }

  // Get current user's patient data
  static Future<Patient?> getCurrentPatient() async {
    try {
      if (!AuthService.isAuthenticated) return null;

      final response = await _client
          .from('patients')
          .select('*')
          .eq('id', AuthService.currentUser!.id)
          .single();

      return Patient.fromMap(response);
    } catch (e) {
      print('Error fetching current patient: $e');
      return null;
    }
  }

  // Get appointments for current user
  static Future<List<Map<String, dynamic>>> getAppointments() async {
    try {
      if (!AuthService.isAuthenticated) {
        print('User not authenticated');
        return [];
      }

      print('Fetching appointments for user: ${AuthService.currentUser!.id}');
      final response = await _client
          .from('appointments')
          .select('*')
          .eq('patient_id', AuthService.currentUser!.id)
          .order('appointment_date', ascending: true);

      print('Raw response: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching appointments: $e');
      return [];
    }
  }

  // Create new appointment
  static Future<bool> createAppointment({
    required String title,
    required String description,
    required DateTime appointmentDate,
    required String appointmentTime,
    String? doctorName,
    String? department,
    String? notes,
  }) async {
    try {
      if (!AuthService.isAuthenticated) {
        print('User not authenticated for creating appointment');
        return false;
      }

      final appointmentData = {
        'patient_id': AuthService.currentUser!.id,
        'appointment_type': title,
        'doctor_name': doctorName ?? 'Dr. Smith',
        'department': department ?? 'General Medicine',
        'appointment_date': appointmentDate.toIso8601String().split('T')[0],
        'appointment_time': appointmentTime,
        'duration_minutes': 30,
        'status': 'Scheduled',
        'notes': notes,
      };

      print('Creating appointment with data: $appointmentData');
      await _client.from('appointments').insert(appointmentData);
      print('Appointment created successfully');

      return true;
    } catch (e) {
      print('Error creating appointment: $e');
      return false;
    }
  }

  // Update appointment
  static Future<bool> updateAppointment({
    required String appointmentId,
    String? title,
    String? description,
    DateTime? appointmentDate,
    String? appointmentTime,
    String? notes,
    String? status,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (title != null) updates['appointment_type'] = title;
      if (description != null) updates['notes'] = description; // Using notes field for description
      if (appointmentDate != null) updates['appointment_date'] = appointmentDate.toIso8601String().split('T')[0];
      if (appointmentTime != null) updates['appointment_time'] = appointmentTime;
      if (notes != null) updates['notes'] = notes;
      if (status != null) updates['status'] = status;

      await _client
          .from('appointments')
          .update(updates)
          .eq('id', appointmentId)
          .eq('patient_id', AuthService.currentUser!.id);

      return true;
    } catch (e) {
      print('Error updating appointment: $e');
      return false;
    }
  }

  // Delete appointment
  static Future<bool> deleteAppointment(String appointmentId) async {
    try {
      await _client
          .from('appointments')
          .delete()
          .eq('id', appointmentId)
          .eq('patient_id', AuthService.currentUser!.id);

      return true;
    } catch (e) {
      print('Error deleting appointment: $e');
      return false;
    }
  }
}
