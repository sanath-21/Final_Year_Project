import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ParticipantCard extends StatelessWidget {
  final Map<String, dynamic> participant;
  final VoidCallback onDelete;

ParticipantCard({required this.participant, required this.onDelete});

@override
Widget build(BuildContext context){
  return Dismissible(key: Key(participant['id'].toString()), 
  direction: DismissDirection.endToStart,
  onDismissed: (direction){
    onDelete();
  },
  background: Container(
    alignment: Alignment.centerRight,
    padding: EdgeInsets.symmetric(horizontal: 20),
    color: Colors.red,
    child: Icon(Icons.delete, color: Colors.white),
  ),
  child: AnimatedContainer(duration: Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(15),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha((0.1 * 255).toInt()),
        blurRadius: 8,
        spreadRadius: 2,
        offset: Offset(0, 3),
      ),
    ],
  ),
  child: ListTile(
    contentPadding: EdgeInsets.all(15),
    leading: CircleAvatar(
      backgroundColor: Colors.blueAccent,
      child: Icon(Icons.person, color: Colors.white),
    ),
    title: Text(
      participant['driver_name'],
      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      'Co-driver: ${participant['co_driver_name']} | Category ${participant['cateegory']}',
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
    ),
    trailing: IconButton(
      icon: Icon(Icons.delete, color: Colors.red),
      onPressed: onDelete,
      ),
  ),
  ),

  );
  
}
}