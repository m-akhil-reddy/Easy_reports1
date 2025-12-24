import 'package:flutter/material.dart';
import 'AddSchedulePopup.dart';
import 'services/patient_service.dart';
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading appointments...');
      final appointments = await PatientService.getAppointments();
      print('Loaded ${appointments.length} appointments');
      setState(() {
        _appointments = appointments;
      });
    } catch (e) {
      print('Error loading appointments: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading appointments: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
         automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight:60,
        title: const Text(
          'Schedules',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize:22,
            color: Color(0xFF1f2b5b),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            onPressed: (){},
            icon: Icon(Icons.person, color: const Color(0xFF1f2b5b), size: width * 0.07),
          ),
        ],
          bottom: PreferredSize(
    preferredSize: const Size.fromHeight(1.0),
    child: Container(
      color: const Color.fromARGB(255, 223, 223, 223), // Light grey line
      height: 1.0,
    ),
  ),
      ),
      body: Column(
        children: [
          CustomHorizontalWeekPicker(
            onDateSelected: (date) {
              _loadAppointments();
            },
          ),
          SizedBox(height: height * 0.025),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _appointments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No appointments scheduled',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to add an appointment',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                        itemCount: _appointments.length,
                        itemBuilder: (context, index) {
                          final appointment = _appointments[index];
                          return _buildAppointmentCard(appointment, width, height);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddSchedulePop(),
          );
          
          // Refresh appointments if a new one was added
          if (result == true) {
            _loadAppointments();
          }
        },
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.add, color: Colors.white, size: width * 0.08),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, double width, double height) {
    final title = appointment['appointment_type'] ?? 'Appointment';
    final doctorName = appointment['doctor_name'] ?? '';
    final department = appointment['department'] ?? '';
    final time = appointment['appointment_time'] ?? '';
    final status = appointment['status'] ?? 'Scheduled';
    final notes = appointment['notes'] ?? '';

    Color statusColor;
    String statusText;
    
    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Completed';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
      case 'no show':
        statusColor = Colors.orange;
        statusText = 'No Show';
        break;
      case 'in progress':
        statusColor = Colors.blue;
        statusText = 'In Progress';
        break;
      case 'confirmed':
        statusColor = Colors.purple;
        statusText = 'Confirmed';
        break;
      default:
        statusColor = Colors.blue;
        statusText = 'Scheduled';
    }

    return Container(
      margin: EdgeInsets.only(bottom: height * 0.015),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.03),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: width * 0.045,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1f2b5b),
                    ),
                  ),
                ),
                if (time.isNotEmpty) ...[
                  Icon(Icons.access_time, size: width * 0.04, color: Colors.grey[600]),
                  SizedBox(width: width * 0.01),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: width * 0.035,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ),
            if (doctorName.isNotEmpty) ...[
              SizedBox(height: height * 0.01),
              Row(
                children: [
                  Icon(Icons.person, size: width * 0.04, color: Colors.blue),
                  SizedBox(width: width * 0.02),
                  Text(
                    'Dr. $doctorName',
                    style: TextStyle(
                      fontSize: width * 0.038,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (department.isNotEmpty) ...[
                    SizedBox(width: width * 0.02),
                    Text(
                      '• $department',
                      style: TextStyle(
                        fontSize: width * 0.035,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (notes.isNotEmpty) ...[
              SizedBox(height: height * 0.01),
              Text(
                'Notes: $notes',
                style: TextStyle(
                  fontSize: width * 0.035,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            SizedBox(height: height * 0.01),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(width * 0.02),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.03,
                    vertical: width * 0.015,
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showAppointmentOptions(appointment),
                  icon: Icon(Icons.more_vert, size: width * 0.05),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentOptions(Map<String, dynamic> appointment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Appointment'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement edit functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Appointment', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteAppointment(appointment['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text('Are you sure you want to delete this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await PatientService.deleteAppointment(appointmentId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAppointments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete appointment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class CustomWeekView extends StatelessWidget {
  const CustomWeekView({super.key});

  final List<String> weekdays = const [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  List<DateTime> getCurrentWeekDates() {
    final now = DateTime.now();
    final int currentWeekday = now.weekday;
    final monday = now.subtract(Duration(days: currentWeekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = getCurrentWeekDates();
    final today = DateTime.now();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isToday = weekDates[i].day == today.day && weekDates[i].month == today.month && weekDates[i].year == today.year;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isToday ? Colors.blueAccent : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        weekdays[i],
                        style: TextStyle(
                          color: isToday ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weekDates[i].day.toString(),
                        style: TextStyle(
                          color: isToday ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          // Removed the bottom row as requested
        ],
      ),
    );
  }
}

class CustomHorizontalWeekPicker extends StatefulWidget {
  final Function(DateTime)? onDateSelected;
  
  const CustomHorizontalWeekPicker({super.key, this.onDateSelected});

  @override
  State<CustomHorizontalWeekPicker> createState() => _CustomHorizontalWeekPickerState();
}

class _CustomHorizontalWeekPickerState extends State<CustomHorizontalWeekPicker> {
  late DateTime _selectedDate;
  late DateTime _currentWeekStart;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _currentWeekStart = _getStartOfWeek(_selectedDate);
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  List<DateTime> _getWeekDates(DateTime weekStart) {
    return List.generate(7, (i) => weekStart.add(Duration(days: i)));
  }

  void _goToPreviousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
      _selectedDate = _currentWeekStart;
    });
  }

  void _goToNextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
      _selectedDate = _currentWeekStart;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _currentWeekStart = _getStartOfWeek(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = _getWeekDates(_currentWeekStart);
    final monthName = _monthName(_selectedDate.month);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "$monthName ${_selectedDate.year}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.calendar_today, size: 20),
                onPressed: _pickDate,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _goToPreviousWeek,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _goToNextWeek,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final date = weekDates[i];
              final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month && date.year == _selectedDate.year;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    widget.onDateSelected?.call(date);
                  },
                  child: Column(
                    children: [
                      Text(
                        _weekdayShort(date.weekday),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.blue : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          date.day.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  String _weekdayShort(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}