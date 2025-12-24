import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Patient Management
  static Future<List<Map<String, dynamic>>> getPatients() async {
    try {
      final response = await _client
          .from('patients')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching patients: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getPatient(String patientId) async {
    try {
      final response = await _client
          .from('patients')
          .select('*')
          .eq('id', patientId)
          .single();
      
      return response;
    } catch (e) {
      print('Error fetching patient: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> createPatient(Map<String, dynamic> patientData) async {
    try {
      final response = await _client
          .from('patients')
          .insert(patientData)
          .select()
          .single();
      
      return response;
    } catch (e) {
      print('Error creating patient: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updatePatient(String patientId, Map<String, dynamic> patientData) async {
    try {
      final response = await _client
          .from('patients')
          .update(patientData)
          .eq('id', patientId)
          .select()
          .single();
      
      return response;
    } catch (e) {
      print('Error updating patient: $e');
      rethrow;
    }
  }

  static Future<void> deletePatient(String patientId) async {
    try {
      await _client
          .from('patients')
          .update({'is_active': false})
          .eq('id', patientId);
    } catch (e) {
      print('Error deleting patient: $e');
      rethrow;
    }
  }

  // Vitals Management
  static Future<List<Map<String, dynamic>>> getVitals(String patientId) async {
    try {
      final response = await _client
          .from('vitals')
          .select('*')
          .eq('patient_id', patientId)
          .order('recorded_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching vitals: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createVital(Map<String, dynamic> vitalData) async {
    try {
      final response = await _client
          .from('vitals')
          .insert(vitalData)
          .select()
          .single();
      
      return response;
    } catch (e) {
      print('Error creating vital: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getLatestVitals(String patientId) async {
    try {
      final response = await _client
          .from('vitals')
          .select('*')
          .eq('patient_id', patientId)
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error fetching latest vitals: $e');
      return null;
    }
  }

  // Appointments Management
  static Future<List<Map<String, dynamic>>> getAppointments(String patientId) async {
    try {
      final response = await _client
          .from('appointments')
          .select('*')
          .eq('patient_id', patientId)
          .order('appointment_date', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching appointments: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getUpcomingAppointments() async {
    try {
      final response = await _client
          .from('upcoming_appointments')
          .select('*');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching upcoming appointments: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> appointmentData) async {
    try {
      final response = await _client
          .from('appointments')
          .insert(appointmentData)
          .select()
          .single();
      
      return response;
    } catch (e) {
      print('Error creating appointment: $e');
      rethrow;
    }
  }

  // Medications Management
  static Future<List<Map<String, dynamic>>> getMedications(String patientId) async {
    try {
      final response = await _client
          .from('medications')
          .select('*')
          .eq('patient_id', patientId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching medications: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getMedicationReminders() async {
    try {
      final response = await _client
          .from('medication_reminders')
          .select('*');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching medication reminders: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createMedication(Map<String, dynamic> medicationData) async {
    try {
      final response = await _client
          .from('medications')
          .insert(medicationData)
          .select()
          .single();
      
      return response;
    } catch (e) {
      print('Error creating medication: $e');
      rethrow;
    }
  }

  static Future<void> markMedicationTaken(String scheduleId, {String? notes}) async {
    try {
      await _client
          .from('medication_schedule')
          .update({
            'taken': true,
            'taken_at': DateTime.now().toIso8601String(),
            if (notes != null) 'notes': notes,
          })
          .eq('id', scheduleId);
    } catch (e) {
      print('Error marking medication as taken: $e');
      rethrow;
    }
  }

  // Notifications Management
  static Future<List<Map<String, dynamic>>> getNotifications(String patientId) async {
    try {
      final response = await _client
          .from('notifications')
          .select('*')
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching notifications: $e');
      rethrow;
    }
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Health Tips Management
  static Future<List<Map<String, dynamic>>> getHealthTips() async {
    try {
      final response = await _client
          .from('health_tips')
          .select('*')
          .eq('is_active', true)
          .order('priority', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching health tips: $e');
      rethrow;
    }
  }

  // Edge Functions
  static Future<Map<String, dynamic>> callPatientManagementFunction(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final response = await _client.functions.invoke(
        'patient-management',
        body: data,
      );
      
      return response.data;
    } catch (e) {
      print('Error calling patient management function: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> callVitalAlertsFunction(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final response = await _client.functions.invoke(
        'vital-alerts',
        body: data,
      );
      
      return response.data;
    } catch (e) {
      print('Error calling vital alerts function: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> callMedicationRemindersFunction(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final response = await _client.functions.invoke(
        'medication-reminders',
        body: data,
      );
      
      return response.data;
    } catch (e) {
      print('Error calling medication reminders function: $e');
      rethrow;
    }
  }

  // Real-time subscriptions
  static RealtimeChannel subscribeToPatientUpdates(String patientId, Function(Map<String, dynamic>) onUpdate) {
    return _client
        .channel('patient_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'patients',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: patientId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  static RealtimeChannel subscribeToVitalsUpdates(String patientId, Function(Map<String, dynamic>) onUpdate) {
    return _client
        .channel('vitals_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'vitals',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'patient_id',
            value: patientId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  static RealtimeChannel subscribeToNotifications(String patientId, Function(Map<String, dynamic>) onUpdate) {
    return _client
        .channel('notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'patient_id',
            value: patientId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }
}
