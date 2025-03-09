import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'track_screen.dart';


class ParticipantScreen extends StatefulWidget{
  @override
  _ParticipantScreenState createState() => _ParticipantScreenState();
}

class _ParticipantScreenState extends State<ParticipantScreen>{
  List<Map<String, dynamic>> participants = [];

  // controllers for user input
  // final TextEditingController _participantNumberController = TextEditingController();
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _coDriverNameController = TextEditingController();
  String _selectedCategory = 'Stock';

  //Fetch all participants from the database
  void fetchParticipants() async{
    List<Map<String, dynamic>> data = await DatabaseHelper.instance.getAllParticipants();
    setState(() {
      participants = data;
    });
  }

  // Add a participant to the database
  void addParticipant() async{
    if( _driverNameController.text.isEmpty|| _coDriverNameController.text.isEmpty){
      return;
    }

    //Get the last participant number from the database
    List<Map<String, dynamic>> allParticipants = await DatabaseHelper.instance.getAllParticipants();
    int nextParticipantNumber = (allParticipants.isEmpty) ? 1 : allParticipants.length+1;

    await DatabaseHelper.instance.insertParticipant({
      'participant_number': nextParticipantNumber,
      'driver_name': _driverNameController.text,
      'co_driver_name': _coDriverNameController.text,
      'category': _selectedCategory
    });

    //Clear fields for next participant
    _driverNameController.clear();
    _coDriverNameController.clear();

    fetchParticipants(); //Refresh list after inserting  
  }

  // Delete a participant by ID
  void deleteParticipant(int id) async{
    await DatabaseHelper.instance.deleteParticipant(id);
    fetchParticipants(); //Refresh the list
  }

  // Show Add Participant Form in Dialog
  void showAddParticipantDialog(){
    showDialog(
      context: context, 
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog){
          return AlertDialog(
            title: Text('Add Participant'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _driverNameController,
                decoration: InputDecoration(labelText: 'Driver Name'),
              ),

              TextField(
                controller: _coDriverNameController,
                decoration: InputDecoration(labelText: 'Co-Driver Name'),
              ),
            
              DropdownButton<String>(
                value: _selectedCategory, 
                onChanged: (newValue){
                  setStateDialog(() {  //This setState does not rebuild the dialog
                    _selectedCategory = newValue!;                
                  });
                },
                items: ['Stock', 'Mod Petrol', 'Mod Diesel', 'Pro', 'Ladies + Pro']
                  .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                  .toList(),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),child: Text('Cancel')),
            ElevatedButton(
              onPressed: (){
                addParticipant();
                setState(() {});  //Refresh UI
              }, 
              child: Text('Add Another'),
              ),
              ElevatedButton(onPressed: (){
                Navigator.pop(context);    //Close Dialog
                Navigator.push(context,
                MaterialPageRoute(builder: (context) => TrackScreen()),   //Navigate to next screen
                );
              }, child: Text('Submit'),
              ),
        ],
        );
        },
      ),
      );
  }

  @override
  void initState(){
    super.initState();
    fetchParticipants(); //Load data on startup
  }  

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('Participants')),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddParticipantDialog,
        child: Icon(Icons.add),),
      body: participants.isEmpty
      ? Center(child: Text("No Participants Added"))
      :ListView.builder(
        itemCount: participants.length,
        itemBuilder: (context, index){
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: ListTile(
              title: Text(participants[index]['driver_name']),
              subtitle: Text(
                'Co-driver: ${participants[index]['co_driver_name']} | Category: ${participants[index]['category']}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteParticipant(participants[index]['id']),
                  ),
            ),      
          );
        },
        ),
    );
  }
}
