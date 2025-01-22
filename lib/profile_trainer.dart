import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart'; // Import přihlašovací stránky
import 'package:intl/intl.dart'; // Import intl package for DateFormat
import 'package:table_calendar/table_calendar.dart'; // Import TableCalendar package

class ProfileTrainer extends StatefulWidget {
  const ProfileTrainer({super.key});

  @override
  State<ProfileTrainer> createState() => _ProfileTrainerState();
}

class _ProfileTrainerState extends State<ProfileTrainer> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();

  // Add training management variables
  Map<String, List<dynamic>> _trainings = {};
  List<dynamic> _selectedTrainings = [];
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isEditing = false; // Add editing state

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchTrainings(); // Fetch trainings on initialization
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data();
          _nameController.text = userData?['name'] ?? '';
          _surnameController.text = userData?['surname'] ?? '';
        });
      }
    }
  }

  Future<void> _fetchTrainings() async {
    if (user != null) {
      final trainingsSnapshot = await FirebaseFirestore.instance
          .collection('training_plans')
          .where('trainer_uid', isEqualTo: user!.uid)
          .get();

      Map<String, List<dynamic>> trainings = {};

      for (var doc in trainingsSnapshot.docs) {
        Timestamp timestamp = doc['scheduled_date_time'];
        DateTime date = timestamp.toDate().toLocal(); // Ensure local time
        String dayKey = DateFormat('yyyy-MM-dd').format(date); // Format date as string

        if (!trainings.containsKey(dayKey)) {
          trainings[dayKey] = [];
        }
        trainings[dayKey]?.add(doc.data());
        print('Training added on: $dayKey');
      }

      setState(() {
        _trainings = trainings;
        String todayKey = DateFormat('yyyy-MM-dd').format(_focusedDay);
        _selectedDay = _focusedDay; // Initialize selected day to today
        _selectedTrainings = _trainings[todayKey] ?? [];
        print('Trainings loaded: $_trainings');
        print('Selected Day: $_selectedDay');
        print('Selected Trainings: $_selectedTrainings');
      });
    }
  }

  Future<void> _updateUserProfile() async {
    if (_nameController.text.isNotEmpty && _surnameController.text.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'name': _nameController.text,
          'surname': _surnameController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil byl úspěšně aktualizován.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba při aktualizaci profilu: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jméno a příjmení jsou povinné.')),
      );
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    String selectedDayKey = DateFormat('yyyy-MM-dd').format(selectedDay);
    print('Day selected: $selectedDayKey');
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedTrainings = _trainings[selectedDayKey] ?? [];
      print('Updated Selected Trainings: $_selectedTrainings');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trainer Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal.shade700, // Changed to a more prominent color
        elevation: 4, // Added elevation for better visibility
        actions: const [
          // ...existing actions...
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 30, 30, 30), // Darker background
                  Colors.grey.shade900
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Icon(
                    Icons.fitness_center,
                    size: 100,
                    color: Colors.teal.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Welcome, ${userData?['name'] ?? 'Trainer'}!',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildEditableUserInfoRow('Name', _nameController),
                const SizedBox(height: 10),
                _buildEditableUserInfoRow('Surname', _surnameController),
                const SizedBox(height: 10),
                _buildUserInfoRow('Email', userData?['email']),
                const SizedBox(height: 20),
                
                // Add TableCalendar widget
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  eventLoader: (day) {
                    String dayKey = DateFormat('yyyy-MM-dd').format(day);
                    List<dynamic> events = _trainings[dayKey] ?? [];
                    print('Events for $dayKey: $events');
                    return events;
                  },
                  onDaySelected: _onDaySelected,
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.tealAccent, // Brighter selected day
                      shape: BoxShape.circle,
                    ),
                    // Remove markerDecoration
                    // markerDecoration: BoxDecoration(
                    //   color: Colors.green, // Changed marker color to green
                    //   shape: BoxShape.circle,
                    // ),
                    outsideDaysVisible: false,
                    weekendTextStyle: TextStyle(color: Colors.orangeAccent),
                    defaultTextStyle: TextStyle(color: Colors.white),
                    holidayTextStyle: TextStyle(color: Colors.redAccent),
                  ),
                  headerStyle: const HeaderStyle(
                    titleTextStyle: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.white70),
                    weekendStyle: TextStyle(color: Colors.orangeAccent),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return const SizedBox();
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                
                // Move training information container here
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _selectedTrainings.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tréninky na tento den:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Column(
                              children: _selectedTrainings.map((training) {
                                Timestamp? timestamp = training['scheduled_date_time'];
                                if (timestamp == null) {
                                  return const SizedBox.shrink(); // Skip if no timestamp
                                }
                                DateTime scheduledTime = timestamp.toDate();

                                // Correctly retrieve the client's full name
                                String clientName = training['client_name'] ?? 'Neznámý klient';

                                return ExpansionTile(
                                  title: Text(
                                    clientName,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    DateFormat('HH:mm').format(scheduledTime),
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Description Row
                                          Row(
                                            children: [
                                              const Icon(Icons.description, color: Colors.tealAccent, size: 20),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'Popis: ${training['description'] ?? 'Bez popisu'}',
                                                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Exercise Type Row
                                          Row(
                                            children: [
                                              const Icon(Icons.fitness_center, color: Colors.tealAccent, size: 20),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'Typ cvičení: ${training['exercise_type'] ?? 'N/A'}',
                                                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Client Name Row
                                          Row(
                                            children: [
                                              const Icon(Icons.person, color: Colors.tealAccent, size: 20),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'Klient: ${training['client_name'] ?? 'N/A'}',
                                                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        )
                      : const Text(
                          'Žádné tréninky pro tento den.',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                ),
                
                const SizedBox(height: 20),
                
                // Update Edit/Update Profile Button based on _isEditing
                _isEditing
                    ? Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            _updateUserProfile();
                            setState(() {
                              _isEditing = false; // Exit edit mode after update
                            });
                          },
                          child: const Text(
                            'Update Profile',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      )
                    : Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _isEditing = true; // Enable edit mode
                            });
                          },
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                const SizedBox(height: 20),

                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut(); // Odhlášení uživatele
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                        (route) => false, // Vymaže stack navigace
                      );
                    },
                    child: const Text(
                      'Log Out',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoRow(String label, String? value) {
    return Row(
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value ?? 'N/A',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // Modify the _buildEditableUserInfoRow to handle editable and non-editable states
  Widget _buildEditableUserInfoRow(String label, TextEditingController controller) {
    return Row(
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _isEditing
              ? TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintStyle: TextStyle(color: Colors.white54),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                )
              : Text(
                  controller.text,
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
      
    );
  }

}

  