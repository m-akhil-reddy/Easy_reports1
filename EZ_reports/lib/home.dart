import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'simplified_report_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;
  
  // Real-time vitals data from Supabase
  List<VitalData> _vitals = [];
  bool _isLoadingVitals = false;

  final List<MedicineData> _medicines = [
    MedicineData(name: 'Metformin', dosage: '500mg', time: '8:00 AM', isTaken: false),
    MedicineData(name: 'Lisinopril', dosage: '10mg', time: '9:00 AM', isTaken: true),
    MedicineData(name: 'Vitamin D', dosage: '1000 IU', time: '12:00 PM', isTaken: false),
  ];

  final List<AppointmentData> _appointments = [
    AppointmentData(title: 'Dr. Smith - Cardiology', date: 'Tomorrow, 2:00 PM', type: 'Doctor Visit'),
    AppointmentData(title: 'Blood Test - Lab', date: 'Friday, 10:00 AM', type: 'Lab Test'),
  ];

  final List<String> _healthTips = [
    '💧 Drink 8 glasses of water today for optimal hydration',
    '🚶‍♂️ Take a 30-minute walk to boost your energy',
    '🥗 Include leafy greens in your next meal for better nutrition',
    '😴 Aim for 7-8 hours of sleep tonight',
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController!,
      curve: Curves.easeInOut,
    ));
    _fadeController!.forward();
    
    // Load vitals data from Supabase
    _loadVitalsData();
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    super.dispose();
  }

  // Load vitals data from Supabase
  Future<void> _loadVitalsData() async {
    setState(() {
      _isLoadingVitals = true;
    });

    try {
      // Check if Supabase is properly initialized
      if (!Supabase.instance.isInitialized) {
        throw Exception('Supabase not initialized');
      }

      // Get patient ID first
      final patientResponse = await Supabase.instance.client
          .from('patients')
          .select('id')
          .eq('patient_id', 'P-2024-001')
          .single();

      if (patientResponse.isEmpty) {
        throw Exception('Patient not found');
      }

      final patientId = patientResponse['id'];

      // Get latest vitals for this patient
      final response = await Supabase.instance.client
          .from('vitals')
          .select()
          .eq('patient_id', patientId)
          .order('recorded_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final latestVitals = response.first;
        List<VitalData> vitals = [];

        // Convert Supabase data to VitalData objects
        if (latestVitals['blood_pressure_systolic'] != null && 
            latestVitals['blood_pressure_diastolic'] != null) {
          vitals.add(VitalData(
            name: 'Blood Pressure',
            value: '${latestVitals['blood_pressure_systolic']}/${latestVitals['blood_pressure_diastolic']}',
            trend: Trend.stable,
            status: HealthStatus.normal,
          ));
        }

        if (latestVitals['heart_rate'] != null) {
          vitals.add(VitalData(
            name: 'Heart Rate',
            value: '${latestVitals['heart_rate']} bpm',
            trend: Trend.stable,
            status: HealthStatus.normal,
          ));
        }

        if (latestVitals['temperature'] != null) {
          vitals.add(VitalData(
            name: 'Temperature',
            value: '${latestVitals['temperature']}°F',
            trend: Trend.stable,
            status: HealthStatus.normal,
          ));
        }

        if (latestVitals['glucose_level'] != null) {
          vitals.add(VitalData(
            name: 'Glucose',
            value: '${latestVitals['glucose_level']} mg/dL',
            trend: Trend.stable,
            status: HealthStatus.normal,
          ));
        }

        if (latestVitals['oxygen_saturation'] != null) {
          vitals.add(VitalData(
            name: 'Oxygen Saturation',
            value: '${latestVitals['oxygen_saturation']}%',
            trend: Trend.stable,
            status: HealthStatus.normal,
          ));
        }

        if (latestVitals['respiratory_rate'] != null) {
          vitals.add(VitalData(
            name: 'Respiratory Rate',
            value: '${latestVitals['respiratory_rate']}/min',
            trend: Trend.stable,
            status: HealthStatus.normal,
          ));
        }

        setState(() {
          _vitals = vitals;
          _isLoadingVitals = false;
        });
      } else {
        setState(() {
          _vitals = [];
          _isLoadingVitals = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingVitals = false;
      });
      print('Error loading vitals: $e');
    }
  }

  // Refresh vitals data
  Future<void> refreshVitals() async {
    await _loadVitalsData();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: _fadeAnimation != null
            ? FadeTransition(
                opacity: _fadeAnimation!,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 32 : 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      SizedBox(height: isTablet ? 32 : 24),
                      if (isTablet) ...[
                        // Tablet layout - 2 columns
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _buildVitalsCard(),
                                  const SizedBox(height: 20),
                                  _buildMedicinesCard(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildAppointmentsCard(),
                                  const SizedBox(height: 20),
                                  _buildHealthTipsCard(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Mobile layout - single column
                        _buildVitalsCard(),
                        const SizedBox(height: 20),
                        _buildMedicinesCard(),
                        const SizedBox(height: 20),
                        _buildAppointmentsCard(),
                        const SizedBox(height: 20),
                        _buildHealthTipsCard(),
                      ],
                      const SizedBox(height: 100), // Space for FAB
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: isTablet ? 32 : 24),
                    if (isTablet) ...[
                      // Tablet layout - 2 columns
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _buildVitalsCard(),
                                const SizedBox(height: 20),
                                _buildMedicinesCard(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: [
                                _buildAppointmentsCard(),
                                const SizedBox(height: 20),
                                _buildHealthTipsCard(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Mobile layout - single column
                      _buildVitalsCard(),
                      const SizedBox(height: 20),
                      _buildMedicinesCard(),
                      const SizedBox(height: 20),
                      _buildAppointmentsCard(),
                      const SizedBox(height: 20),
                      _buildHealthTipsCard(),
                    ],
                    const SizedBox(height: 100), // Space for FAB
                  ],
                ),
              ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SimplifiedReportPage(),
              ),
            );
          },
          backgroundColor: const Color(0xFF059669),
          elevation: 0,
          icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
          label: const Text(
            'Scan Report',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E40AF),
            Color(0xFF3B82F6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E40AF).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.waving_hand,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Morning, Rahul',
                      style: TextStyle(
                        fontSize: isTablet ? 32 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here\'s your health summary for today',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        color: Colors.white.withOpacity(0.9),
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  DateTime.now().toString().split(' ')[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsCard() {
    return RefreshIndicator(
      onRefresh: refreshVitals,
      child: Container(
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
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Color(0xFFDC2626),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latest Vitals',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Real-time health metrics',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFDBEAFE),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF2563EB),
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'AI Summary',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2563EB),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoadingVitals)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Color(0xFF3B82F6),
                  ),
                ),
              )
            else if (_vitals.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.favorite_outline,
                        size: 48,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No vitals recorded yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.withOpacity(0.7),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first vital reading',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.withOpacity(0.5),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._vitals.map((vital) => _buildVitalItem(vital)),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildVitalItem(VitalData vital) {
    Color statusColor;
    IconData statusIcon;
    
    switch (vital.status) {
      case HealthStatus.normal:
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle;
        break;
      case HealthStatus.warning:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.warning;
        break;
      case HealthStatus.alert:
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.error;
        break;
    }

    IconData trendIcon;
    Color trendColor;
    switch (vital.trend) {
      case Trend.up:
        trendIcon = Icons.trending_up;
        trendColor = const Color(0xFF10B981);
        break;
      case Trend.down:
        trendIcon = Icons.trending_down;
        trendColor = const Color(0xFFEF4444);
        break;
      case Trend.stable:
        trendIcon = Icons.trending_flat;
        trendColor = const Color(0xFF6B7280);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vital.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vital.value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: trendColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(trendIcon, color: trendColor, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicinesCard() {
    return Container(
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
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medication,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Medicines',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Track your medication schedule',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ..._medicines.map((medicine) => _buildMedicineItem(medicine)),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineItem(MedicineData medicine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: medicine.isTaken ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: medicine.isTaken ? const Color(0xFFBBF7D0) : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: medicine.isTaken,
              onChanged: (value) {
                setState(() {
                  medicine.isTaken = value ?? false;
                });
              },
              activeColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.medication_liquid, color: Color(0xFF8B5CF6), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: medicine.isTaken ? const Color(0xFF6B7280) : const Color(0xFF111827),
                    fontFamily: 'Poppins',
                    decoration: medicine.isTaken ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${medicine.dosage} • ${medicine.time}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          if (medicine.isTaken)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Taken',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsCard() {
    return Container(
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
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Appointments',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your scheduled visits',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ..._appointments.map((appointment) => _buildAppointmentItem(appointment)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentItem(AppointmentData appointment) {
    IconData appointmentIcon = appointment.type == 'Doctor Visit' 
        ? Icons.person 
        : Icons.science;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(appointmentIcon, color: const Color(0xFF3B82F6), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.date,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              appointment.type,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTipsCard() {
    return Container(
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
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    color: Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Tips',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Personalized recommendations',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFDE68A),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Color(0xFFD97706),
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'AI Generated',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD97706),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ..._healthTips.map((tip) => _buildHealthTipItem(tip)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement ask AI functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Ask AI feature coming soon!',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      backgroundColor: const Color(0xFF8B5CF6),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                label: const Text(
                  'Ask AI Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthTipItem(String tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Color(0xFFF59E0B),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                fontFamily: 'Poppins',
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Data models
class VitalData {
  final String name;
  final String value;
  final Trend trend;
  final HealthStatus status;

  VitalData({
    required this.name,
    required this.value,
    required this.trend,
    required this.status,
  });
}

class MedicineData {
  final String name;
  final String dosage;
  final String time;
  bool isTaken;

  MedicineData({
    required this.name,
    required this.dosage,
    required this.time,
    required this.isTaken,
  });
}

class AppointmentData {
  final String title;
  final String date;
  final String type;

  AppointmentData({
    required this.title,
    required this.date,
    required this.type,
  });
}

enum Trend { up, down, stable }
enum HealthStatus { normal, warning, alert }
