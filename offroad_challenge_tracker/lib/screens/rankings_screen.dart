import 'package:flutter/material.dart';
import '../services/database_helper.dart';

//Rankings Screen
class RankingsScreen extends StatefulWidget{
  @override
  _RankingsScreenState createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen>{
  List<Map<String, dynamic>> rankings = [];

  void fetchRankings() async {
    List<Map<String, dynamic>> data = await DatabaseHelper.instance.getRankings();
    setState(() {
      rankings = data;
    });
  }

  @override
  void initState(){
    super.initState();
    fetchRankings();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('Rankings')),
      body: rankings.isEmpty
        ? Center(child: Text('No rankings available'))
        :ListView.builder(
          itemCount: rankings.length,
          itemBuilder: (context, index){
            return ListTile(
              title: Text("Participant ID: ${rankings[index]['participant_id']}"),
              subtitle: Text("Rank: ${rankings[index]['rank']}"),
            );
          },
          ),
    );
  }
}