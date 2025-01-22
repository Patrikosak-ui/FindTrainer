import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
// ignore: depend_on_referenced_packages

class TrainerOverview extends StatelessWidget {
  final String clientUid;
  final String clientName;

  const TrainerOverview({super.key, required this.clientUid, required this.clientName});

  Stream<List<RecordData>> _streamProgress() {
    try {
      print('Streaming progress for clientUid: $clientUid');
      return FirebaseFirestore.instance
          .collection('progress')
          .where('clientUid', isEqualTo: clientUid)
          .orderBy('date') // Ensure a composite index exists for 'clientUid' and 'date'
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                return RecordData.fromMap(doc.data());
              }).toList());
    } catch (e) {
      print('Error streaming progress: $e');
      return Stream.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progres klienta',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade700,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 30, 30, 30),
                Colors.grey.shade900,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20.0),
          child: StreamBuilder<List<RecordData>>(
            stream: _streamProgress(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                if (snapshot.error is FirebaseException && (snapshot.error as FirebaseException).code == 'failed-precondition') {
                  return Center(
                    child: Text(
                      'Chybí Firestore index. Prosím vytvořte složený index pro "clientUid" a "date" v Firebase konzoli.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Center(child: Text('Chyba: ${snapshot.error}'));
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final progressList = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: progressList.length,
                  itemBuilder: (context, index) {
                    final progress = progressList[index];
                    return ExpansionTile(
                      title: Text(
                        'Datum: ${DateFormat('dd.MM.yyyy').format(progress.date)}',
                        style: TextStyle(color: Colors.white),
                      ),
                      children: [
                        ListTile(
                          title: Text(
                            'Svalová skupina: ${progress.muscleGroup}',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ...progress.exercises.map((exercise) {
                          return ExpansionTile(
                            title: Text(
                              'Cvičení: ${exercise.name}',
                              style: TextStyle(color: Colors.white),
                            ),
                            children: exercise.series.map((s) {
                              return ListTile(
                                title: Text(
                                  'Váha: ${s.weight} kg, Opakování: ${s.reps}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  'Pocit: ${s.feeling}',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ],
                    );
                  },
                );
              } else {
                return const Center(child: Text('Žádná data o progresu nejsou k dispozici.'));
              }
            },
          ),
        ),
      ),
    );
  }
}

class RecordData {
  final DateTime date;
  final String muscleGroup;
  final List<Exercise> exercises;
  final double weight;
  final double strength;
  final double performance;
  final String feeling;

  RecordData({
    required this.date,
    required this.muscleGroup,
    required this.exercises,
    required this.weight,
    required this.strength,
    required this.performance,
    required this.feeling,
  });

  factory RecordData.fromMap(Map<String, dynamic> data) {
    return RecordData(
      date: (data['date'] as Timestamp).toDate(),
      muscleGroup: data['muscleGroup'] as String,
      exercises: (data['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
          .toList(),
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      strength: (data['strength'] as num?)?.toDouble() ?? 0.0,
      performance: (data['performance'] as num?)?.toDouble() ?? 0.0,
      feeling: data['feeling'] as String? ?? '', // Provide a default value if 'feeling' is null
    );
  }
}

class Exercise {
  final String name;
  final List<Series> series;

  Exercise({
    required this.name,
    required this.series,
  });

  factory Exercise.fromMap(Map<String, dynamic> data) {
    var seriesFromFirestore = data['series'] as List<dynamic>;
    List<Series> seriesList = seriesFromFirestore.map((s) => Series.fromMap(s as Map<String, dynamic>)).toList();

    return Exercise(
      name: data['exercise'] as String,
      series: seriesList,
    );
  }
}

class Series {
  final double weight;
  final int reps;
  final double feeling;

  Series({
    required this.weight,
    required this.reps,
    required this.feeling,
  });

  factory Series.fromMap(Map<String, dynamic> data) {
    return Series(
      weight: (data['weight'] as num).toDouble(),
      reps: data['reps'] as int,
      feeling: (data['feeling'] as num).toDouble(),
    );
  }
}


