import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_helper.dart';
import 'track_screen.dart';
import '../widgets/participant_card.dart';

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
    
    print("Fetchedd Participants: $data");
    
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

    int insertedId = await DatabaseHelper.instance.insertParticipant({
      'participant_number': nextParticipantNumber,
      'driver_name': _driverNameController.text,
      'co_driver_name': _coDriverNameController.text,
      'category': _selectedCategory
    });

  if(insertedId > 0){
    print('Participant added successfully with ID: $insertedId');
  } else {
    print('Failed to add participant.');
  }

    fetchParticipants(); //Refresh list after inserting
    setState(() {});  //Ensure UI updates

    //Clear fields for next participant
    _driverNameController.clear();
    _coDriverNameController.clear();  
  }

  // Delete a participant by ID
  void deleteParticipant(int id) async{
    await DatabaseHelper.instance.deleteParticipant(id);
    fetchParticipants(); //Refresh the list
  }
  @override
  void initState() {
    super.initState();
    fetchParticipants();
  }

  // Show Add Participant Form in Dialog
  void showAddParticipantDialog(){
    showDialog(
      context: context,
      builder:(context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Add Participant', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
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
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },

                items: ['Stock', 'Mod Petrol', 'Mod Diesel', 'Pro', 'Ladies + Pro']
                .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                .toList(),
              ),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            
            ElevatedButton(
              onPressed: (){
                addParticipant();
                Navigator.pop(context); // Close Dialog before reopening
                Future.delayed(Duration(milliseconds: 500), (){
                  fetchParticipants(); //Fetch data after delay
                });
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
        ),
        );
  }


  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Participants', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddParticipantDialog,
        label: Text('Add Participant', style: TextStyle(color: Colors.white)),
        icon: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blueAccent,
        ),
      body: participants.isEmpty
      ? Center(child: Text("No Participants Added", style: GoogleFonts.poppins(fontSize: 16)))
      :ListView.builder(
        itemCount: participants.length,
        itemBuilder: (context, index){
          return ParticipantCard(
            participant: participants[index], 
            onDelete: () => deleteParticipant(participants[index]['id']),
          );
        },
        ),
    );
  }
}
