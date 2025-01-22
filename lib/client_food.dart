import 'package:flutter/material.dart';

class ClientFood extends StatelessWidget {
  const ClientFood({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food'),
      ),
      body: const Center(
        child: Text('Client Food Page'),
      ),
    );
  }
}
