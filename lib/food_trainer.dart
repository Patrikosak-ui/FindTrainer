import 'package:flutter/material.dart';

class FoodTrainer extends StatelessWidget {
  final String clientUid;
  final String clientName;

  const FoodTrainer({
    Key? key,
    required this.clientUid,
    required this.clientName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jídelníček pro $clientName'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: Center(
        child: Text('Zde bude možnost přidávat jídelníčky.'),
      ),
    );
  }
}
