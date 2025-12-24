import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Basic scaffold so it can be used inside a nested Navigator or directly
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'No notifications yet',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
