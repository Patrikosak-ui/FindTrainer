import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestsTrainer extends StatelessWidget {
  const RequestsTrainer({super.key});

  // Funkce pro získání jména a příjmení klienta na základě clientUid
 Future<Map<String, String>> _getClientNameAndSurname(String clientUid) async {
  try {
    // Načítání uživatelských dat z kolekce users
    var userDoc = await FirebaseFirestore.instance.collection('users').doc(clientUid).get();

    // Kontrola, jestli dokument existuje
    if (userDoc.exists) {
      var data = userDoc.data();

      // Zajištění, že hodnoty existují, jinak použijeme defaultní hodnoty
      return {
        'name': data?['name'] ?? 'Neznámé jméno',
        'surname': data?['surname'] ?? 'Neznámé příjmení',
      };
    } else {
      // Pokud dokument neexistuje, vrátíme výchozí hodnoty
      return {
        'name': 'Neznámé jméno',
        'surname': 'Neznámé příjmení',
      };
    }
  } catch (e) {
    // Zpracování chyby a vrácení výchozích hodnot
    print('Chyba při načítání dat klienta: $e');
    return {
      'name': 'Neznámé jméno',
      'surname': 'Neznámé příjmení',
    };
  }
}

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Přihlaste se prosím.'));
    }

    // Vytvoříme GlobalKey pro ScaffoldMessenger
    final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

    return Scaffold(
      key: scaffoldMessengerKey, // Přiřadíme GlobalKey
      appBar: AppBar(
        title: const Text('Žádosti od klientů'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('trainer_uid', isEqualTo: user.uid) // Filtrování pouze pro trenéra
            .where('status', isEqualTo: 'pending') // Filtrování pouze na čekající žádosti
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Žádné nové žádosti.'));
          }

          var requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var request = requests[index];
              var clientUid = request['client_uid']; // UID klienta
              var requestId = request.id; // ID žádosti

              return FutureBuilder<Map<String, String>>(
                future: _getClientNameAndSurname(clientUid),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text('Načítání...'),
                    );
                  }

                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      title: Text('Chyba při načítání klienta'),
                    );
                  }

                  var clientData = userSnapshot.data!;
                  var name = clientData['name'];
                  var surname = clientData['surname'];

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text('$name $surname'),
                      subtitle: Text('UID klienta: $clientUid'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              // Schválení žádosti
                              await FirebaseFirestore.instance.collection('clients').add({
                                'uid': clientUid, // UID klienta
                                'name': name, // Jméno klienta
                                'surname': surname, // Příjmení klienta
                              });

                              await FirebaseFirestore.instance
                                  .collection('requests')
                                  .doc(requestId)
                                  .update({'status': 'approved'});

                              // Použití GlobalKey pro zobrazení SnackBar
                              scaffoldMessengerKey.currentState?.showSnackBar(
                                const SnackBar(content: Text('Klient byl přijat.')),
                              );
                            },
                            child: const Text('Schválit'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              // Zamítnutí žádosti
                              await FirebaseFirestore.instance
                                  .collection('requests')
                                  .doc(requestId)
                                  .update({'status': 'declined'});

                              // Použití GlobalKey pro zobrazení SnackBar
                              scaffoldMessengerKey.currentState?.showSnackBar(
                                const SnackBar(content: Text('Žádost byla zamítnuta.')),
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Zamítnout'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
