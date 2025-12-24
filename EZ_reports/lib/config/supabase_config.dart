class SupabaseConfig {
  // Supabase project credentials
  static const String supabaseUrl = 'https://wfoupmxfjzlirakcorhi.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indmb3VwbXhmanpsaXJha2NvcmhpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAxNDQ2ODksImV4cCI6MjA3NTcyMDY4OX0.oMphyr7HG1XO6Z-Si_KpPiaCRVCU46tmndH8Zv-ExWY';
  static const String supabaseServiceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indmb3VwbXhmanpsaXJha2NvcmhpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDE0NDY4OSwiZXhwIjoyMDc1NzIwNjg5fQ.xBG5ootEeunkD27g6nkH9n84DX3r1_0sxUAlKTFngUs';
  
  // Edge Functions URLs
  static const String patientManagementFunctionUrl = '$supabaseUrl/functions/v1/patient-management';
  static const String vitalAlertsFunctionUrl = '$supabaseUrl/functions/v1/vital-alerts';
  static const String medicationRemindersFunctionUrl = '$supabaseUrl/functions/v1/medication-reminders';
  
  // Database table names
  static const String patientsTable = 'patients';
  static const String vitalsTable = 'vitals';
  static const String appointmentsTable = 'appointments';
  static const String medicationsTable = 'medications';
  static const String medicationScheduleTable = 'medication_schedule';
  static const String notificationsTable = 'notifications';
  static const String healthTipsTable = 'health_tips';
  static const String staffTable = 'staff';
  
  // View names
  static const String patientSummaryView = 'patient_summary';
  static const String upcomingAppointmentsView = 'upcoming_appointments';
  static const String medicationRemindersView = 'medication_reminders';
}
