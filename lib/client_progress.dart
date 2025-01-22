import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ClientProgress extends StatefulWidget {
  const ClientProgress({super.key});

  @override
  _ClientProgressState createState() => _ClientProgressState();
}

class _ClientProgressState extends State<ClientProgress> {
  final _formKey = GlobalKey<FormState>();
  String? selectedMuscleGroup;
  List<Map<String, dynamic>> exercises = [];
  DateTime selectedDate = DateTime.now();
  double? performance;
  double? weight;

  final Map<String, List<String>> muscleExercises = {
    'Nohy': [
      'Dřepy',
      'Legpress',
      'Předkopávání',
      'Zakopávání',
      'Lýtka',
      'Hiptrusty',
      'RDL',
      'Bulhary',
      'Dřepy – klasické',
      'Sumo',
      'S činkou vpředu',
      'Hacken dřepy',
      'Výpady – vpřed, vzad, do strany',
      'Rumunský mrtvý tah',
      'Předkopávání na stroji',
      'Hip Thrust',
      'Výpony na lýtka se závažím',
    ],
    'Záda': [
      'Kladka ze zhora',
      'Kladka v sedě',
      'Přítahy v předklonu',
      'Shyby',
      'Deadlift',
      'Shyby – nadhmatem',
      'Shyby – podhmatem',
      'Stahování kladky na hrudník',
      'Přítahy činky v předklonu',
      'Přítahy jednoručky k tělu v předklonu',
      'Přítahy na spodní kladce',
      'Pullover s činkou',
      'Přítahy na T-Baru',
      'Face Pulls na kladce',
    ],
    'Prsa (Kozy)': [
      'Bench press',
      'Peck Deck',
      'Rozpažování s jednoručkami',
      'Stlačování kladek před tělem',
      'Tlaky s jednoručkami – rovná a šikmá lavice',
      'Pullover s jednoručkou',
      'Dipy na bradlech',
    ],
    'Biceps': [
      'Bicepsové zdvihy s činkou',
      'Bicepsové zdvihy s jednoručkami',
      'Zdvihy na Scottově lavici',
      'Zdvihy s EZ činkou',
      'Zdvihy s kladkou',
      'Obrácené zdvihy nadhmatem',
      'Izolované zdvihy na stroji',
    ],
    'Triceps': [
      'Bench press úzkým úchopem',
      'Francouzský tlak s EZ činkou',
      'Kickbacks s jednoručkami',
      'Tricepsové stlačování kladky',
      'Kliky na bradlech',
      'Overhead Cable Extension',
      'Tlaky s lanem na kladce',
    ],
    'Ramena': [
      'Tlaky na ramena s činkou',
      'Tlaky s jednoručkami nad hlavu',
      'Upažování s jednoručkami',
      'Předpažování s jednoručkami',
      'Tlaky na ramena na stroji',
      'Obrácené rozpažky',
      'Face Pulls na kladce',
      'Arnoldovy tlaky',
    ],
  };

  void _addExercise() {
    if (selectedMuscleGroup != null) {
      setState(() {
        exercises.add({
          'exercise': null,
          'series': [],
        });
      });
    }
  }

  void _addSeries(int index) {
    setState(() {
      exercises[index]['series'] ??= []; // Ensure 'series' is initialized
      exercises[index]['series'].add({
        'weight': 0.0,
        'reps': 0,
        'feeling': 50.0, // Renamed from 'performance'
      });
    });
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.teal.shade700,
              onPrimary: Colors.white,
              surface: Colors.grey.shade800,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey.shade800,
            textTheme: TextTheme(
              headlineSmall: TextStyle(color: Colors.teal.shade700, fontSize: 20),
              bodyMedium: TextStyle(color: Colors.white),
            ),
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _submitProgress() {
    if (_formKey.currentState!.validate()) {
      if (exercises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Přidejte alespoň jeden cvik')),
        );
        return;
      }

      bool hasEmptySeries = false;
      for (var exercise in exercises) {
        if (exercise['series'].isEmpty) {
          hasEmptySeries = true;
          break;
        }
      }

      if (hasEmptySeries) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Každý cvik musí mít alespoň jednu sérii')),
        );
        return;
      }

      _formKey.currentState!.save();
      final clientUid = FirebaseAuth.instance.currentUser?.uid;
      final progressData = {
        'date': Timestamp.fromDate(selectedDate),
        'muscleGroup': selectedMuscleGroup,
        'exercises': exercises,
        'clientUid': clientUid,
      };
      FirebaseFirestore.instance.collection('progress').add(progressData).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pokrok úspěšně odeslán')),
        );
        // Optionally, reset the form
        _formKey.currentState!.reset();
        setState(() {
          selectedMuscleGroup = null;
          exercises = [];
          selectedDate = DateTime.now();
        });
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nepodařilo se odeslat pokrok: $error')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pokrok',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal.shade700, // Changed to match profile
        elevation: 4, // Added elevation
      ),
      body: Padding(
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
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0), // Reduced horizontal padding
          child: Form(
            key: _formKey,
            child: ScrollConfiguration(
              behavior: ScrollBehavior(),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Svalová skupina',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          items: muscleExercises.keys
                              .map((group) => DropdownMenuItem(
                                    value: group,
                                    child: Text(
                                      group,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ))
                              .toList(),
                          dropdownColor: Colors.grey[850], // Changed to dark background
                          onChanged: (value) {
                            setState(() {
                              selectedMuscleGroup = value;
                              exercises = [];
                            });
                          },
                          validator: (value) => value == null ? 'Vyberte svalovou skupinu' : null,
                        ),
                        if (selectedMuscleGroup != null) ...[
                          ElevatedButton(
                            onPressed: _addExercise,
                            child: const Text('Přidat cvik'),
                          ),
                          ...List.generate(exercises.length, (index) {
                            // Zkontrolujte, zda index stále platí před renderováním
                            if (index >= exercises.length) {
                              print('Skipping rendering for invalid exercise index: $index');
                              return Container(); // Vrátí prázdný widget místo pokusu o přístup k neplatnému indexu
                            }

                            print('Rendering exercise at index $index. Total exercises: ${exercises.length}');
                            return Dismissible(
                              key: Key(exercises[index]['exercise'] ?? index.toString()),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) {
                                setState(() {
                                  exercises.removeAt(index);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Cvik odstraněn')),
                                );
                              },
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(Icons.delete, color: Colors.white),
                              ),
                              child: Column(
                                key: ValueKey(exercises[index]['exercise'] ?? index),
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          decoration: const InputDecoration(
                                            labelText: 'Cvik',
                                            labelStyle: TextStyle(color: Colors.white),
                                          ),
                                          items: muscleExercises[selectedMuscleGroup]!
                                              .map((exercise) => DropdownMenuItem(
                                                    value: exercise,
                                                    child: Text(
                                                      exercise,
                                                      style: TextStyle(color: Colors.white),
                                                    ),
                                                  ))
                                              .toList(),
                                          dropdownColor: Colors.grey[850],
                                          onChanged: (value) {
                                            setState(() {
                                              exercises[index]['exercise'] = value;
                                            });
                                          },
                                          validator: (value) => value == null ? 'Vyberte cvik' : null,
                                        ),
                                      ),
                                      SizedBox(width: 4), // Further reduced horizontal spacing
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red, size: 16), // Further reduced icon size
                                        onPressed: () {
                                          setState(() {
                                            exercises.removeAt(index);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Cvik odstraněn')),
                                            );
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12), // Added spacing
                                  ElevatedButton(
                                    onPressed: () => _addSeries(index),
                                    child: const Text('Přidat sérii'),
                                  ),
                                  SizedBox(height: 12), // Added spacing
                                  ...List.generate(exercises[index]['series'].length, (seriesIndex) {
                                    // Zkontrolujte, zda seriesIndex stále platí před renderováním
                                    if (seriesIndex >= exercises[index]['series'].length) {
                                      print('Skipping rendering for invalid series index: $seriesIndex for exercise $index');
                                      return Container(); // Vrátí prázdný widget místo pokusu o přístup k neplatnému indexu
                                    }

                                    print('Rendering series at index $seriesIndex for exercise $index. Total series: ${exercises[index]['series'].length}');
                                    return Dismissible(
                                      key: Key('$index-$seriesIndex'),
                                      direction: DismissDirection.endToStart,
                                      onDismissed: (direction) {
                                        setState(() {
                                          exercises[index]['series'].removeAt(seriesIndex);
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Série odstraněna')),
                                        );
                                      },
                                      background: Container(
                                        color: Colors.red,
                                        alignment: Alignment.centerRight,
                                        padding: EdgeInsets.symmetric(horizontal: 10),
                                        child: Icon(Icons.delete, color: Colors.white),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start, // Align to start
                                              children: [
                                                TextFormField(
                                                  decoration: InputDecoration(
                                                    labelText: 'Závaží (kg)',
                                                    labelStyle: TextStyle(color: Colors.white),
                                                    isDense: true, // Reduce vertical space
                                                    contentPadding: EdgeInsets.symmetric(vertical: 4.0), // Further adjusted padding
                                                  ),
                                                  style: TextStyle(color: Colors.white),
                                                  keyboardType: TextInputType.number,
                                                  onSaved: (value) {
                                                    exercises[index]['series'][seriesIndex]['weight'] = double.tryParse(value ?? '0') ?? 0.0;
                                                  },
                                                  validator: (value) => value == null || value.isEmpty ? 'Zadejte váhu' : null,
                                                ),
                                                SizedBox(height: 2), // Further reduced spacing
                                                TextFormField(
                                                  decoration: InputDecoration(
                                                    labelText: 'Počet opakování',
                                                    labelStyle: TextStyle(color: Colors.white),
                                                    isDense: true, // Reduce vertical space
                                                    contentPadding: EdgeInsets.symmetric(vertical: 4.0), // Further adjusted padding
                                                  ),
                                                  style: TextStyle(color: Colors.white),
                                                  keyboardType: TextInputType.number,
                                                  onSaved: (value) {
                                                    exercises[index]['series'][seriesIndex]['reps'] = int.tryParse(value ?? '0') ?? 0;
                                                  },
                                                  validator: (value) => value == null || value.isEmpty ? 'Zadejte počet opakování' : null,
                                                ),
                                                SizedBox(height: 2), // Further reduced spacing
                                                Text('Pocit', style: TextStyle(color: Colors.white, fontSize: 12)), // Reduced font size
                                                Slider(
                                                  value: exercises[index]['series'][seriesIndex]['feeling'] ?? 50.0,
                                                  min: 1,
                                                  max: 100,
                                                  divisions: 99,
                                                  label: (exercises[index]['series'][seriesIndex]['feeling'] ?? 50.0).round().toString(),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      exercises[index]['series'][seriesIndex]['feeling'] = value;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 4), // Further reduced horizontal spacing
                                          IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red, size: 16), // Further reduced icon size
                                            onPressed: () {
                                              setState(() {
                                                exercises[index]['series'].removeAt(seriesIndex);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Série odstraněna')),
                                                );
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  SizedBox(height: 16), // Added spacing between exercises
                                ],
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Text(
                              "Datum: ${DateFormat('dd.MM.yyyy').format(selectedDate)}",
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: () => _selectDate(context),
                              child: const Text('Vybrat datum'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _submitProgress,
                          child: const Text(
                            'Odeslat',
                            style: TextStyle(fontSize: 18, color: Colors.white),
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
      ),
    );
  }
}