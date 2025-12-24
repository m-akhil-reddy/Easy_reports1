import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_vital_page.dart';
import 'services/auth_service.dart';

class PatientPage extends StatefulWidget {
  const PatientPage({super.key});

  @override
  State<PatientPage> createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _vitalsData = [];
  bool _isLoadingVitals = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadVitalsData();
  }

  // Responsive breakpoints
  bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1024;
  bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1024;
  
  // Responsive grid columns
  int getVitalsGridColumns(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4;
  }
  
  // Responsive padding
  EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(16);
    if (isTablet(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(32);
  }
  
  // Responsive font sizes
  double getResponsiveFontSize(BuildContext context, double baseSize) {
    if (isMobile(context)) return baseSize;
    if (isTablet(context)) return baseSize * 1.1;
    return baseSize * 1.2;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load vitals data from Supabase
  Future<void> _loadVitalsData() async {
    setState(() {
      _isLoadingVitals = true;
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
        throw Exception('Patient record not found for current user');
      }

      final patientId = patientResponse['id'];

      // Get vitals for this patient
      final response = await Supabase.instance.client
          .from('vitals')
          .select()
          .eq('patient_id', patientId)
          .order('recorded_at', ascending: false)
          .limit(10);

      setState(() {
        _vitalsData = List<Map<String, dynamic>>.from(response);
        _isLoadingVitals = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingVitals = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading vitals: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  // Refresh vitals data
  Future<void> _refreshVitals() async {
    await _loadVitalsData();
  }

  // Build vitals cards from Supabase data
  List<Widget> _buildVitalsFromData() {
    if (_vitalsData.isEmpty) return [];

    // Get the latest vitals record
    final latestVitals = _vitalsData.first;

    List<Widget> vitalCards = [];

    // Define vital configurations
    final vitalConfigs = {
      'Blood Pressure': {
        'icon': Icons.favorite, 
        'color': Colors.red, 
        'unit': 'mmHg',
        'getValue': () {
          final systolic = latestVitals['blood_pressure_systolic'];
          final diastolic = latestVitals['blood_pressure_diastolic'];
          if (systolic != null && diastolic != null) {
            return '$systolic/$diastolic';
          }
          return null;
        }
      },
      'Heart Rate': {
        'icon': Icons.favorite, 
        'color': Colors.red, 
        'unit': 'bpm',
        'getValue': () => latestVitals['heart_rate']?.toString(),
      },
      'Temperature': {
        'icon': Icons.thermostat, 
        'color': Colors.orange, 
        'unit': '°F',
        'getValue': () => latestVitals['temperature']?.toString(),
      },
      'Glucose': {
        'icon': Icons.water_drop, 
        'color': Colors.blue, 
        'unit': 'mg/dL',
        'getValue': () => latestVitals['glucose_level']?.toString(),
      },
      'Oxygen Saturation': {
        'icon': Icons.air, 
        'color': Colors.green, 
        'unit': '%',
        'getValue': () => latestVitals['oxygen_saturation']?.toString(),
      },
      'Respiratory Rate': {
        'icon': Icons.air, 
        'color': Colors.purple, 
        'unit': '/min',
        'getValue': () => latestVitals['respiratory_rate']?.toString(),
      },
    };

    // Create cards for each vital that has data
    vitalConfigs.forEach((vitalName, config) {
      final getValue = config['getValue'] as Function;
      final value = getValue() as String?;
      if (value != null && value.isNotEmpty) {
        vitalCards.add(_buildVitalCard(
          vitalName,
          value,
          config['unit'] as String,
          config['icon'] as IconData,
          config['color'] as Color,
        ));
      }
    });

    return vitalCards;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: isMobile(context) ? 56 : (isTablet(context) ? 64 : 72),
        title: Text(
          'Patient Details',
          style: TextStyle(
            fontSize: getResponsiveFontSize(context, isMobile(context) ? 20 : 24),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: !isMobile(context), // Center title on tablet/desktop, left align on mobile
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            color: const Color(0xFF1F2937),
            size: isMobile(context) ? 18 : 20,
          ),
        ),
        actions: [
          // Responsive action buttons
          if (isMobile(context)) ...[
            // Mobile: Only edit button
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit patient feature coming soon!'),
                    backgroundColor: Color(0xFF3B82F6),
                  ),
                );
              },
              icon: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF1F2937),
                size: 22,
              ),
            ),
          ] else ...[
            // Tablet/Desktop: Multiple action buttons
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share patient data'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              },
              icon: Icon(
                Icons.share_outlined,
                color: const Color(0xFF1F2937),
                size: isTablet(context) ? 24 : 26,
              ),
            ),
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Print patient report'),
                    backgroundColor: Color(0xFF8B5CF6),
                  ),
                );
              },
              icon: Icon(
                Icons.print_outlined,
                color: const Color(0xFF1F2937),
                size: isTablet(context) ? 24 : 26,
              ),
            ),
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit patient feature coming soon!'),
                    backgroundColor: Color(0xFF3B82F6),
                  ),
                );
              },
              icon: Icon(
                Icons.edit_outlined,
                color: const Color(0xFF1F2937),
                size: isTablet(context) ? 24 : 26,
              ),
            ),
          ],
          SizedBox(width: isMobile(context) ? 4 : 8),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isMobile(context) ? 60 : 70),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: isMobile(context) ? 16 : 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(isMobile(context) ? 10 : 12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(isMobile(context) ? 10 : 12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF6B7280),
              labelStyle: TextStyle(
                fontSize: getResponsiveFontSize(context, isMobile(context) ? 12 : 14),
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: getResponsiveFontSize(context, isMobile(context) ? 12 : 14),
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      
                      Text('Info'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                     
                      Text('Vitals'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    
                      Text('Report'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    
                      Text('Timeline'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show action menu
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildActionItem(
                          icon: Icons.favorite_outline,
                          title: 'Add Vital',
                          subtitle: 'Record new vital signs',
                          color: const Color(0xFFEF4444),
                          onTap: () async {
                            Navigator.pop(context); // Close the bottom sheet
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddVitalPage(),
                              ),
                            );
                            
                            // Refresh vitals data if new data was saved
                            if (result == true) {
                              await _refreshVitals();
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildActionItem(
                          icon: Icons.edit_outlined,
                          title: 'Edit Patient',
                          subtitle: 'Update patient information',
                          color: const Color(0xFF3B82F6),
                        ),
                        const SizedBox(height: 16),
                        _buildActionItem(
                          icon: Icons.share_outlined,
                          title: 'Share Data',
                          subtitle: 'Share patient information',
                          color: const Color(0xFF059669),
                        ),
                        const SizedBox(height: 16),
                        _buildActionItem(
                          icon: Icons.print_outlined,
                          title: 'Print Report',
                          subtitle: 'Generate patient report',
                          color: const Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.more_horiz, color: Colors.white),
        label: const Text(
          'Actions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildVitalsTab(),
          _buildReportTab(),
          _buildTimelineTab(),
        ],
      ),
    );
  }

  // Helper method for action items in floating action button
  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {
        Navigator.pop(context); // Close the bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title feature coming soon!'),
            backgroundColor: color,
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Profile Card
          Container(
            padding: EdgeInsets.all(isMobile(context) ? 20 : 28),
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
                // Profile Picture
                Container(
                  width: isMobile(context) ? 80 : 100,
                  height: isMobile(context) ? 80 : 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: isMobile(context) ? 40 : 50,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'John Smith',
                  style: TextStyle(
                    fontSize: getResponsiveFontSize(context, 28),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Patient ID: P-2024-001',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                // Patient Details Grid - Responsive
                if (isMobile(context)) ...[
                  // Mobile: 2 columns
                  Row(
                    children: [
                      Expanded(child: _buildInfoItem('Age', '45 years')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoItem('Gender', 'Male')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildInfoItem('Blood Type', 'O+')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoItem('Weight', '75 kg')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildInfoItem('Height', '175 cm')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoItem('BMI', '24.5')),
                    ],
                  ),
                ] else ...[
                  // Tablet/Desktop: 3 columns
                  Row(
                    children: [
                      Expanded(child: _buildInfoItem('Age', '45 years')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoItem('Gender', 'Male')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoItem('Blood Type', 'O+')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildInfoItem('Weight', '75 kg')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoItem('Height', '175 cm')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoItem('BMI', '24.5')),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Contact Information
          _buildSectionCard(
            title: 'Contact Information',
            icon: Icons.contact_phone_outlined,
            children: [
              _buildContactItem(Icons.phone, '+1 (555) 123-4567'),
              _buildContactItem(Icons.email, 'john.smith@email.com'),
              _buildContactItem(Icons.location_on, '123 Main St, City, State'),
            ],
          ),
          const SizedBox(height: 24),
          // Emergency Contact
          _buildSectionCard(
            title: 'Emergency Contact',
            icon: Icons.emergency_outlined,
            children: [
              _buildContactItem(Icons.person, 'Jane Smith (Wife)'),
              _buildContactItem(Icons.phone, '+1 (555) 987-6543'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vitals Grid - Responsive
            if (_isLoadingVitals)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(
                    color: Color(0xFF3B82F6),
                  ),
                ),
              )
            else if (_vitalsData.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.monitor_heart_outlined,
                        size: 64,
                        color: Color(0xFF9CA3AF),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No vitals recorded yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the Add Vital button to record patient vitals',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9CA3AF),
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: getVitalsGridColumns(context),
                crossAxisSpacing: isMobile(context) ? 12 : 16,
                mainAxisSpacing: isMobile(context) ? 12 : 16,
                childAspectRatio: isMobile(context) ? 1.1 : 1.2,
                children: _buildVitalsFromData(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTab() {
    return SingleChildScrollView(
      padding: getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reports Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.description,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Medical Reports',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        'Latest test results and reports',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Add report feature coming soon!'),
                        backgroundColor: Color(0xFF059669),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Reports List
          ...List.generate(5, (index) => _buildReportItem(index)),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    return SingleChildScrollView(
      padding: getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timeline,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Medical Timeline',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        'Patient history and events',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Timeline Items
          ...List.generate(6, (index) => _buildTimelineItem(index)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF3B82F6),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF6B7280),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF374151),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalCard(String name, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(isMobile(context) ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: isMobile(context) ? 20 : 24,
                  ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'NORMAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: TextStyle(
              fontSize: getResponsiveFontSize(context, 14),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: getResponsiveFontSize(context, 24),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(int index) {
    final reports = [
      {'name': 'Blood Test Report', 'date': 'Dec 15, 2024', 'type': 'Lab Report'},
      {'name': 'X-Ray Chest', 'date': 'Dec 10, 2024', 'type': 'Imaging'},
      {'name': 'ECG Report', 'date': 'Dec 8, 2024', 'type': 'Cardiology'},
      {'name': 'Urine Analysis', 'date': 'Dec 5, 2024', 'type': 'Lab Report'},
      {'name': 'MRI Brain', 'date': 'Dec 1, 2024', 'type': 'Imaging'},
    ];
    
    final report = reports[index];
    
    return Container(
      margin: EdgeInsets.only(bottom: isMobile(context) ? 12 : 16),
      padding: EdgeInsets.all(isMobile(context) ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile(context) ? 10 : 12),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.description,
              color: const Color(0xFF059669),
              size: isMobile(context) ? 20 : 24,
            ),
          ),
          SizedBox(width: isMobile(context) ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['name']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report['date']!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report['type']!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF059669),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Viewing ${report['name']}'),
                  backgroundColor: const Color(0xFF059669),
                ),
              );
            },
            icon: const Icon(
              Icons.visibility_outlined,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(int index) {
    final events = [
      {'title': 'Appointment with Dr. Johnson', 'time': '2:30 PM', 'date': 'Dec 20, 2024', 'type': 'Appointment'},
      {'title': 'Blood Test Completed', 'time': '10:15 AM', 'date': 'Dec 15, 2024', 'type': 'Test'},
      {'title': 'Medication Prescribed', 'time': '3:45 PM', 'date': 'Dec 12, 2024', 'type': 'Prescription'},
      {'title': 'X-Ray Examination', 'time': '11:30 AM', 'date': 'Dec 10, 2024', 'type': 'Examination'},
      {'title': 'Initial Consultation', 'time': '9:00 AM', 'date': 'Dec 8, 2024', 'type': 'Consultation'},
      {'title': 'Patient Registration', 'time': '8:30 AM', 'date': 'Dec 1, 2024', 'type': 'Registration'},
    ];
    
    final event = events[index];
    
    Color eventColor;
    IconData eventIcon;
    
    switch (event['type']) {
      case 'Appointment':
        eventColor = const Color(0xFF3B82F6);
        eventIcon = Icons.calendar_today;
        break;
      case 'Test':
        eventColor = const Color(0xFF059669);
        eventIcon = Icons.science;
        break;
      case 'Prescription':
        eventColor = const Color(0xFF8B5CF6);
        eventIcon = Icons.medication;
        break;
      case 'Examination':
        eventColor = const Color(0xFFF59E0B);
        eventIcon = Icons.search;
        break;
      case 'Consultation':
        eventColor = const Color(0xFFEF4444);
        eventIcon = Icons.person;
        break;
      default:
        eventColor = const Color(0xFF6B7280);
        eventIcon = Icons.info;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: isMobile(context) ? 12 : 16),
      padding: EdgeInsets.all(isMobile(context) ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile(context) ? 10 : 12),
            decoration: BoxDecoration(
              color: eventColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              eventIcon,
              color: eventColor,
              size: isMobile(context) ? 20 : 24,
            ),
          ),
          SizedBox(width: isMobile(context) ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Color(0xFF6B7280),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${event['time']} • ${event['date']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: eventColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event['type']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: eventColor,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
