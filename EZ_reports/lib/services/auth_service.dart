import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get current user
  static User? get currentUser => _client.auth.currentUser;

  // Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  // Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
        },
      );

      if (response.user != null) {
        // Create patient record in our database
        await _createPatientRecord(
          userId: response.user!.id,
          email: email,
          fullName: fullName,
          phone: phone,
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with phone number (OTP)
  static Future<void> signInWithPhone({
    required String phone,
  }) async {
    try {
      await _client.auth.signInWithOtp(phone: phone);
    } catch (e) {
      rethrow;
    }
  }

  // Verify OTP
  static Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    try {
      return await _client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  static Future<UserResponse> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;

      return await _client.auth.updateUser(
        UserAttributes(data: updates),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Create patient record in our database
  static Future<void> _createPatientRecord({
    required String userId,
    required String email,
    required String fullName,
    required String phone,
  }) async {
    try {
      // Generate a unique patient ID
      final patientId = 'P-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      
      // Split full name into first and last name
      final nameParts = fullName.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await _client.from('patients').insert({
        'id': userId, // Use Supabase user ID as primary key
        'patient_id': patientId,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'date_of_birth': DateTime(1990, 1, 1).toIso8601String().split('T')[0], // Default date
        'gender': 'Other', // Default gender
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating patient record: $e');
      // Don't rethrow as this is not critical for authentication
    }
  }

  // Get patient data for current user
  static Future<Map<String, dynamic>?> getCurrentPatient() async {
    try {
      if (!isAuthenticated) return null;

      final response = await _client
          .from('patients')
          .select('*')
          .eq('id', currentUser!.id)
          .single();

      return response;
    } catch (e) {
      print('Error fetching patient data: $e');
      return null;
    }
  }

  // Stream of auth state changes
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Listen to auth state changes
  static void listenToAuthChanges(Function(AuthState) callback) {
    _client.auth.onAuthStateChange.listen(callback);
  }
}
