import 'package:flutter/material.dart';
import 'Notification.dart';
import 'home.dart';
import 'patient.dart';
import 'schedule.dart';
import 'services/auth_service.dart';
class Bottomnav extends StatefulWidget {
  const Bottomnav({super.key});

  @override
  State<Bottomnav> createState() => _BottomnavState();
}

class _BottomnavState extends State<Bottomnav> {
  int _selectedIndex = 0;

  final List _pages = [
  const HomePage(),      // Using the new HomePage widget
  const PatientPage(),   // Using the new PatientPage widget
  const SchedulePage(),  // Using the actual SchedulePage widget
  const Center(child: Text('Resources Page')),
];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await AuthService.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Image.asset(
                'assets/images/logo.png',
                height: 130,
                width: 130,
                fit: BoxFit.contain,
              ),
              actions: [
                Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(8),
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationsPage()),
                          );
                        },
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Color(0xFF1f2b5b),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.all(8),
                  child: IconButton(
                    onPressed: _handleLogout,
                    icon: const Icon(
                      Icons.logout,
                      color: Color(0xFF1f2b5b),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  color: const Color.fromARGB(255, 126, 126, 126),
                  height: 0.5,
                ),
              ),
            )
          : null,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: const Color.fromARGB(255, 226, 233, 236),
        elevation: 10,
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side
              Row(
                children: [
                  _buildNavItem(icon: Icons.home, index: 0),
                  _buildNavItem(icon: Icons.person_add_alt_outlined, index: 1),
                ],
              ),
              // Right side
              Row(  
                children: [  
      Padding(
      padding: const EdgeInsets.only(left: 0), // 👈 Move Schedule icon to right
      child: Transform.scale(
        scale: 0.85, // 👈 Scale down just the Schedule icon
        child: _buildNavItem(icon: Icons.calendar_today, index: 2),
      ),
    ),
    Padding(
      padding: const EdgeInsets.only(left: 0), // 👈 Move Schedule icon to right
      child: Transform.scale(
        scale: 0.85, // 👈 Scale down just the Schedule icon
        child:  _buildNavItem(icon: Icons.description, index: 3),
      ),
    ),
                 
                  
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => openDialog(context),
        backgroundColor: Colors.white,
        shape: const CircleBorder(),
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [Color(0xFF2720ff)],
              stops: [ 0.55],
            ),
          ),
          child: const Icon(Icons.mic, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index}) {
    final isSelected = _selectedIndex == index;

    return MaterialButton(
      onPressed: () => _onItemTapped(index),
      minWidth: 60,
       child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1), // 👈 reduce horizontal padding
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.blue : Colors.black54),
          const SizedBox(height: 4),
        ],
      ),
    ),
    );
  }
}
Future<void> openDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.blueAccent.withOpacity(0.15), width: 1.5),
      ),
      elevation: 10,
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2720ff),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2720ff).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.mic, color: Colors.white, size: 32),
      ),
      title: const Text(
        'Voice Assistant',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 22, color: Color(0xFF1f2b5b), fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Speak into the microphone to give commands.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          _buildActionItem('• Search for patient information'),
          _buildActionItem('• Add notes through voice'),
          const SizedBox(height: 10),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF2720ff),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
          ),
          child: const Text(
            'Dismiss',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}
Widget _buildActionItem(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w400),
      textAlign: TextAlign.left,
    ),
  );
}