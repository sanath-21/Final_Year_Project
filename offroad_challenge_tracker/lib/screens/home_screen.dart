import 'package:flutter/material.dart';
import 'participant_screen.dart';
import 'rankings_screen.dart';

class HomeScreen extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Offroad Challenge Tracker")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (context)=> ParticipantScreen())), 
                child: Text("Manage Participants"),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (context) => RankingsScreen())), 
                    child: Text("View Rankings"),
                    ),
          ],
        ),
      ),
    );
  }
}