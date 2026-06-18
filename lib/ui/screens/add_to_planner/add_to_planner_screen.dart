import 'package:flutter/material.dart';

class AddToPlannerScreen extends StatelessWidget {
  final String placeId;
  final String tripId;

  const AddToPlannerScreen({
    super.key,
    required this.placeId,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add to Planner')),
      body: Center(
        child: Text(
          'Add to Planner Screen\nPlace: $placeId, Trip: $tripId\n(To be implemented later)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
