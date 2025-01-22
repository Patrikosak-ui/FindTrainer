import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart'; // Import login page
// import 'package:table_calendar/table_calendar.dart'; // Removed TableCalendar import

class ProfileClient extends StatefulWidget {
  const ProfileClient({super.key});

  @override
  State<ProfileClient> createState() => _ProfileClientState();
}

class _ProfileClientState extends State<ProfileClient> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  String? trainerName; // Pro ukládání jména trenéra
  String? trainerUid; // Add variable to store trainer UID
  // Map<DateTime, List<dynamic>> _trainings = {}; // Removed trainings map
  // List<dynamic> _selectedTrainings = []; // Removed selected trainings list
  // CalendarFormat _calendarFormat = CalendarFormat.month; // Removed calendar format
  // DateTime _focusedDay = DateTime.now(); // Removed focused day
  // DateTime? _selectedDay; // Removed selected day
  // bool _isExpanded = false; // Removed expansion state
  bool _isEditing = false; // Add editing state
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    // _fetchTrainings(); // Removed fetching trainings
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
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
        });
      }

      // Načteme trenéra z requests kolekce
      _fetchTrainerData();
    }
  }

  Future<void> _fetchTrainerData() async {
    if (user != null) {
      final requestSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('client_uid', isEqualTo: user!.uid)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      if (requestSnapshot.docs.isNotEmpty) {
        var trainerUidFetched = requestSnapshot.docs[0]['trainer_uid'];
        final trainerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(trainerUidFetched)
            .get();

        if (trainerDoc.exists) {
          setState(() {
            trainerName = trainerDoc['name'];
            trainerUid = trainerUidFetched; // Store trainer UID
            _nameController.text = userData?['name'] ?? '';
            _surnameController.text = userData?['surname'] ?? '';
          });
          // _fetchTrainings(); // Fetch trainings after trainerUid is set
        }
      }
    }
  }

  // Removed _fetchTrainings method

  Future<void> _updateUserProfile() async {
    if (_nameController.text.isNotEmpty && _surnameController.text.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'name': _nameController.text,
          'surname': _surnameController.text,
        });

        setState(() {
          _isEditing = false; // Exit edit mode after update
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

  // Removed _onDaySelected method

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Client Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal.shade700, // Changed to a more prominent color
        elevation: 4, // Added elevation for better visibility
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color.fromARGB(255, 0, 0, 0), Colors.grey.shade800],
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
                    Icons.account_circle,
                    size: 100,
                    color: Colors.teal.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Welcome, ${userData?['name'] ?? 'Client'}!',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 20),
                _isEditing
                    ? _buildEditableUserInfoRow('Name', _nameController)
                    : _buildUserInfoRow('Name', userData?['name']),
                const SizedBox(height: 10),
                _isEditing
                    ? _buildEditableUserInfoRow('Surname', _surnameController)
                    : _buildUserInfoRow('Surname', userData?['surname']),
                const SizedBox(height: 10),
                _buildUserInfoRow('Email', userData?['email']),
                const SizedBox(height: 20),
                if (trainerName != null) 
                  _buildUserInfoRow('Trainer', trainerName), // Zobrazení jména trenéra
                const SizedBox(height: 20), 

                // Removed TableCalendar widget and trainings display

                // ...existing buttons...
                const SizedBox(height: 20),
                if (_isEditing)
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
                      onPressed: _updateUserProfile,
                      child: const Text(
                        'Update Profile',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                if (!_isEditing)
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
                      onPressed: () {
                        setState(() {
                          _isEditing = true; // Enable edit mode
                          _nameController.text = userData?['name'] ?? '';
                          _surnameController.text = userData?['surname'] ?? '';
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
                      // Odhlášení uživatele a přesměrování na login page
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(), // LoginPage jako náhrada za Navigator.pop(context)
                        ),
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
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter $label',
              hintStyle: const TextStyle(color: Colors.white54),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
