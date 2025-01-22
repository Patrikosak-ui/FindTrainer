import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import balíčku intl
import 'package:intl/date_symbol_data_local.dart'; // Import for initializing locales
// import 'package:table_calendar/table_calendar.dart'; // Remove TableCalendar package import

class TrainerStats extends StatefulWidget {
  final String clientUid;
  final String clientName;

  const TrainerStats({
    super.key,
    required this.clientUid,
    required this.clientName,
  });

  @override
  _TrainerStatsState createState() => _TrainerStatsState();
}

class _TrainerStatsState extends State<TrainerStats> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedExerciseType;

  final List<String> _exerciseTypes = [
    'Kardio',
    'Silový trénink',
    'Flexibilita',
    'Vytrvalost',
  ];

  // Remove calendar-related variables
  // Map<DateTime, List<dynamic>> _trainings = {};
  // List<dynamic> _selectedTrainings = [];
  // CalendarFormat _calendarFormat = CalendarFormat.month;
  // DateTime _focusedDay = DateTime.now();
  // DateTime? _selectedDay;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _assignPlan() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTime != null &&
        _selectedExerciseType != null) {
      try {
        DateTime scheduledDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        ); // Use local time

        await FirebaseFirestore.instance.collection('training_plans').add({
          'client_uid': widget.clientUid,
          'client_name': widget.clientName,
          'description': _descriptionController.text,
          'scheduled_date_time': scheduledDateTime,
          'exercise_type': _selectedExerciseType,
          'trainer_uid': FirebaseAuth.instance.currentUser?.uid,
          'status': 'approved', // Ensure status is set appropriately
          'created_at': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tréninkový plán byl úspěšně přiřazen.')),
        );
        _formKey.currentState!.reset();
        setState(() {
          _selectedDate = null;
          _selectedTime = null;
          _selectedExerciseType = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba při přiřazování plánu: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vyplňte prosím všechny údaje.')),
      );
    }
  }

  String _formatDate(DateTime date) {
    // Použití formátování pro český jazyk
    return DateFormat('d. MMMM yyyy', 'cs_CZ').format(date);
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm', 'cs_CZ').format(dt);
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('cs_CZ', null); // Initialize the locale
    // _fetchTrainings(); // Remove fetching trainings
  }

  // Remove fetching trainings method
  // Future<void> _fetchTrainings() async {
  //   final trainingsSnapshot = await FirebaseFirestore.instance
  //       .collection('training_plans')
  //       .where('trainer_uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
  //       .get();

  //   Map<DateTime, List<dynamic>> trainings = {};

  //   for (var doc in trainingsSnapshot.docs) {
  //     Timestamp timestamp = doc['scheduled_date_time'];
  //     DateTime date = timestamp.toDate();
  //     DateTime day = DateTime(date.year, date.month, date.day);
  //     if (!trainings.containsKey(day)) {
  //       trainings[day] = [];
  //     }
  //     trainings[day]?.add(doc.data());
  //   }

  //   setState(() {
  //     _trainings = trainings;
  //   });
  // }

  // Remove day selection handler
  // void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
  //   setState(() {
  //     _selectedDay = selectedDay;
  //     _focusedDay = focusedDay;
  //     _selectedTrainings = _trainings[selectedDay] ?? [];
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Přiřadit plán pro ${widget.clientName}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
        backgroundColor: Colors.teal.shade700, // Changed to a more prominent color
        elevation: 4, // Added elevation for better visibility
        actions: const [
          // ...you can add actions if needed...
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
                    'Přiřadit trénink',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Popis tréninku:',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          hintText: 'Popis tréninku',
                          hintStyle: TextStyle(color: Colors.white54),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Popis je povinný.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Datum tréninku:',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      Row(
                        children: [
                          Text(
                            _selectedDate != null
                                ? _formatDate(_selectedDate!)
                                : 'Vyberte datum',
                            style: const TextStyle(color: Colors.white),
                          ),
                          TextButton(
                            onPressed: _pickDate,
                            child: const Text(
                              'Vybrat',
                              style: TextStyle(color: Colors.tealAccent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Čas tréninku:',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      Row(
                        children: [
                          Text(
                            _selectedTime != null
                                ? _formatTime(_selectedTime!)
                                : 'Vyberte čas',
                            style: const TextStyle(color: Colors.white),
                          ),
                          TextButton(
                            onPressed: _pickTime,
                            child: const Text(
                              'Vybrat',
                              style: TextStyle(color: Colors.tealAccent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Typ cvičení:',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedExerciseType,
                        hint: const Text(
                          'Vyberte typ cvičení',
                          style: TextStyle(color: Colors.white54),
                        ),
                        dropdownColor: Colors.grey.shade800,
                        decoration: const InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        items: _exerciseTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedExerciseType = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Vyberte typ cvičení.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
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
                          onPressed: _assignPlan,
                          child: const Text(
                            'Přiřadit plán',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
