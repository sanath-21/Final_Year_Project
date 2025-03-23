import 'package:flutter/material.dart';

class ParticipantCard extends StatelessWidget {
  final Map<String, dynamic> participant;
  final VoidCallback onDelete;

ParticipantCard({required this.participant, required this.onDelete});

@override
Widget build(BuildContext context){
  return Card(
    margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
    child: ListTile(
      title: Text(participant['driver_name']),
      subtitle: Text(
        'Co-driver: ${participant['co_driver_name']} | Category: ${participant['category']}',
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete, color: Colors.red),
        onPressed: onDelete,
        ),
    ),
  );
}
}