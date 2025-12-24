import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';

class AddVitalPage extends StatefulWidget {
  const AddVitalPage({super.key});

  @override
  State<AddVitalPage> createState() => _AddVitalPageState();
}

class _AddVitalPageState extends State<AddVitalPage> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _availableVitals = [
    'Blood Pressure',
    'Glucose',
    'Temperature',
    'Oxygen Saturation',
    'Heart Rate',
    'Respiratory Rate',
  ];
  
  final Set<String> _selectedVitals = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for all vitals
    for (String vital in _availableVitals) {
      _controllers[vital] = TextEditingController();
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF1F2937),
            size: 20,
          ),
        ),
        title: const Text(
          'Patient Vitals',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vital Selection Section
              const Text(
                'select vitals to record',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              
              // Vital Selection Chips
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _availableVitals.map((vital) {
                  final isSelected = _selectedVitals.contains(vital);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedVitals.remove(vital);
                        } else {
                          _selectedVitals.add(vital);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFBBDEFB),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        vital,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF1976D2),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 32),
              
              // Input Fields for Selected Vitals
              ..._selectedVitals.map((vital) => _buildVitalInputField(vital)),
              
              const SizedBox(height: 40),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitVitals,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalInputField(String vital) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vital,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controllers[vital],
            decoration: InputDecoration(
              hintText: 'Enter $vital',
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontFamily: 'Poppins',
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF3B82F6),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1F2937),
              fontFamily: 'Poppins',
            ),
            validator: (value) {
              if (_selectedVitals.contains(vital) && (value == null || value.isEmpty)) {
                return 'Please enter $vital';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitVitals() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVitals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one vital to record'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user is authenticated
      if (!AuthService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Check if Supabase is properly initialized
      if (!Supabase.instance.isInitialized) {
        throw Exception('Supabase not initialized');
      }

      // Get current user's patient data
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Get patient ID using the authenticated user's ID
      final patientResponse = await Supabase.instance.client
          .from('patients')
          .select('id')
          .eq('id', currentUser.id)
          .single();

      if (patientResponse.isEmpty) {
        throw Exception('Patient not found');
      }

      final patientId = patientResponse['id'];

      // Prepare vital data according to the new schema
      final vitalData = <String, dynamic>{
        'patient_id': patientId,
        'recorded_at': DateTime.now().toIso8601String(),
        'recorded_by': 'Mobile App',
      };

      // Add selected vitals with their values
      for (String vital in _selectedVitals) {
        final value = _controllers[vital]!.text.trim();
        
        switch (vital) {
          case 'Blood Pressure':
            // Parse blood pressure (e.g., "120/80")
            if (value.contains('/')) {
              final parts = value.split('/');
              if (parts.length == 2) {
                vitalData['blood_pressure_systolic'] = int.tryParse(parts[0].trim());
                vitalData['blood_pressure_diastolic'] = int.tryParse(parts[1].trim());
              }
            }
            break;
          case 'Heart Rate':
            vitalData['heart_rate'] = int.tryParse(value);
            break;
          case 'Temperature':
            vitalData['temperature'] = double.tryParse(value);
            break;
          case 'Oxygen Saturation':
            vitalData['oxygen_saturation'] = double.tryParse(value);
            break;
          case 'Respiratory Rate':
            vitalData['respiratory_rate'] = int.tryParse(value);
            break;
          case 'Glucose':
            vitalData['glucose_level'] = double.tryParse(value);
            break;
        }
      }

      // Insert into Supabase vitals table
      await Supabase.instance.client
          .from('vitals')
          .insert(vitalData);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vitals recorded successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        
        // Navigate back
        Navigator.pop(context, true); // Return true to indicate data was saved
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving vitals: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
