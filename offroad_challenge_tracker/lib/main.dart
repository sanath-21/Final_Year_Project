import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ParticipantScreen(),
    );
  }
}

class ParticipantScreen extends StatefulWidget{
  @override
  _ParticipantScreenState createState() => _ParticipantScreenState();
}

class _ParticipantScreenState extends State<ParticipantScreen>{
  List<Map<String, dynamic>> participants = [];

  // Add a participant to the database
  void addParticipant() async{
    await DatabaseHelper.instance.insertParticipant({
      'participant_number':1;
      'driver_name': 'John Doe',
      'co_driver_name': 'Jane Doe',
      'category': 'Stock'
    });
    fetchParticipants(); //Refresh list after inserting
  }

  // Fetch all participants from the database
  void fetchParticipants() async{
    List<Map<String, dynamic>> data = await DatabaseHelper.instance.getAllParticipants();
    setState(() {
      participants = data;
    });
  }
  @override
  void initState(){
    super.initState();
    fetchParticipants(); //Load data on startup
  }  

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('Participants'),),
      body: Column(
        children: [
          ElevatedButton(onPressed: addParticipant, child: Text('Add Participant'),),
          Expanded(
            child: ListView.builder(
              itemCount: participants.length,
              itemBuilder: (context, index){
                return ListTile(
                  title: Text(participants[index]['driver_name']),
                  subtitle: Text('Co-driver: ${participants[index]['co_driver_name']}| Category: ${participants[index]['category']}'),
                );
              },
              ),
              ),
        ],
      ),
    );
  }
}
