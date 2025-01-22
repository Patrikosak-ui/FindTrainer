import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_client.dart';
import 'client_progress.dart'; // Import ClientProgress page
import 'client_food.dart'; // Import ClientFood page
import 'client_table.dart'; // Import ClientTable page

class MainPageClient extends StatefulWidget {
  const MainPageClient({super.key});

  @override
  State<MainPageClient> createState() => _MainPageClientState();
}

class _MainPageClientState extends State<MainPageClient> {
  bool isConnected = false;
  String? connectedTrainerId;
  Set<String> trainersWithActiveRequests = {};

  @override
  void initState() {
    super.initState();
    _checkClientStatus();
  }

  Future<void> _checkClientStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Kontrola připojení
      var approvedSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('client_uid', isEqualTo: user.uid)
          .where('status', isEqualTo: 'approved')
          .get();

      if (approvedSnapshot.docs.isNotEmpty) {
        setState(() {
          isConnected = true;
          connectedTrainerId = approvedSnapshot.docs.first['trainer_uid'];
        });
      }

      // Načtení aktivních žádostí
      var activeRequestsSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('client_uid', isEqualTo: user.uid)
          .where('status', whereIn: ['pending', 'approved'])
          .get();

      setState(() {
        trainersWithActiveRequests = activeRequestsSnapshot.docs
            .map((doc) => doc['trainer_uid'] as String)
            .toSet();
      });
    } catch (e) {
      debugPrint('Chyba při kontrole stavu klienta: $e');
    }
  }

  Future<void> _sendRequest(String trainerUid) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String clientUid = user.uid;
      String clientName = user.displayName ?? 'Klient';

      // Přidání nové žádosti
      await FirebaseFirestore.instance.collection('requests').add({
        'trainer_uid': trainerUid,
        'client_uid': clientUid,
        'client_name': clientName,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        trainersWithActiveRequests.add(trainerUid);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Žádost byla odeslána.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba při odesílání žádosti: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hlavní stránka klienta',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal.shade700,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileClient(),
                ),
              );
            },
          ),
        ],
      ),
      body: isConnected ? _buildConnectedTrainerView() : _buildAvailableTrainersView(),
    );
  }

  Widget _buildConnectedTrainerView() {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(connectedTrainerId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Došlo k chybě: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Text('Nenalezen trenér.'),
          );
        }

        var trainerData = snapshot.data!.data()!;
        var trainerName = trainerData['name'] ?? 'Neznámý trenér';

        return Card(
          color: Colors.grey.shade900,
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(
              trainerName,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Máte přiřazeného trenéra.',
              style: TextStyle(color: Colors.white70),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.blue),
                  onPressed: () {
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClientTable(
                            clientUid: user.uid, // Pass clientUid
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Uživatel není přihlášen.'),
                        ),
                      );
                    }
                  },
                  tooltip: 'Kalendář',
                ),
                IconButton(
                  icon: const Icon(Icons.show_chart, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClientProgress(),
                      ),
                    );
                  },
                  tooltip: 'Progres',
                ),
                IconButton(
                  icon: const Icon(Icons.restaurant_menu, color: Colors.teal), // Changed icon
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClientFood(),
                      ),
                    );
                  },
                  tooltip: 'Jídelníček',
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  onPressed: () async {
                    try {
                      var requestSnapshot = await FirebaseFirestore.instance
                          .collection('requests')
                          .where('client_uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                          .where('trainer_uid', isEqualTo: connectedTrainerId)
                          .where('status', isEqualTo: 'approved')
                          .get();

                      if (requestSnapshot.docs.isNotEmpty) {
                        await FirebaseFirestore.instance
                            .collection('requests')
                            .doc(requestSnapshot.docs.first.id)
                            .delete();

                        setState(() {
                          isConnected = false;
                          connectedTrainerId = null;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Odpojení od trenéra bylo úspěšné.')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Chyba při odpojování: $e')),
                      );
                    }
                  },
                  tooltip: 'Odpojit se',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvailableTrainersView() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'trainer')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Došlo k chybě: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Žádní trenéři k dispozici.'));
        }

        var trainers = snapshot.data!.docs;

        return ListView.builder(
          itemCount: trainers.length,
          itemBuilder: (context, index) {
            var trainerData = trainers[index].data();
            var trainerName = trainerData['name'] ?? 'Neznámý trenér';
            var trainerUid = trainers[index].id;

            bool canSendRequest = !trainersWithActiveRequests.contains(trainerUid);

            return Card(
              color: Colors.grey.shade900,
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(
                  trainerName,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  canSendRequest ? 'Klikněte pro žádost o přijetí.' : 'Žádost je aktivní.',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canSendRequest ? Colors.teal.shade600 : Colors.grey,
                  ),
                  onPressed: canSendRequest ? () => _sendRequest(trainerUid) : null,
                  child: const Text('Žádost'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}