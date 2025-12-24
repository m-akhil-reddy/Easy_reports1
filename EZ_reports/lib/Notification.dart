import 'package:flutter/material.dart';
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color.fromARGB(0, 255, 255, 255),
          elevation: 0,
          toolbarHeight: 80,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Notifications',style:TextStyle(color:Color(0xFF1f2b5b),fontWeight:FontWeight.bold,fontSize:20),),
          actions:[
            IconButton(onPressed:(){}, icon:const Icon(Icons.search, color: Color(0xFF1f2b5b)))
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40.0),
            child: Container(
              color: const Color.fromARGB(0, 255, 255, 255),
              child: const TabBar(
                tabs:[
  Tab(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.warning, size: 18), // smaller icon
        SizedBox(height: 4),
        Text(
          'Alerts',
          style: TextStyle(fontSize: 10), // smaller text
        ),
      ],
    ),
  ),
  Tab(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.notifications_active, size: 18),
        SizedBox(height: 4),
        Text(
          'Reminders',
          style: TextStyle(fontSize: 10),
        ),
      ],
    ),
  ),
],

                  // Tab(icon:Icon(Icons.warning),text:'Alerts',),
                  // Tab(icon:Icon(Icons.notifications_active),text:'Remainders'),
                
              ),
            ),
          ),
        ),
        body: TabBarView(
          children:[
            Container(
              child:Column(
                children:[
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    height: 130,
                    width: 350,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Medication Alert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Text('High Criticality', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                                const SizedBox(height: 4),
                                const Row(
                                  children: [
                                    Icon(Icons.person, size: 16, color: Colors.red),
                                    Text('John Doe Room-304', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                    Text('10:00 AM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                            onPressed: () {
                              print('Tick pressed!');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    height: 130,
                    width: 350,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color.fromARGB(255, 40, 167, 40).withOpacity(0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 41, 194, 66).withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Medication Alert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Text('Normal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Row(
                                  children: [
                                    Icon(Icons.person, size: 16),
                                    Text('Rama Room-402', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                    Text('10:00 AM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                            onPressed: () {
                              print('Tick pressed!');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
           
            ),
            Container(
              child:Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    child:const Text('Remainders'),
                  ),
                ],
              ),
            ),
          ]
        )
      ),
    );
  }
}
