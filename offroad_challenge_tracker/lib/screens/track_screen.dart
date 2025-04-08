import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_helper.dart';

class TrackScreen extends StatefulWidget {
  @override
  _TrackScreenState createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  final TextEditingController _trackNameController = TextEditingController();
  final TextEditingController _trackNumberController = TextEditingController();

  List<Map<String, dynamic>> tracks = [];

  @override
  void initState() {
    super.initState();
    fetchTracks();
  }

  void fetchTracks() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query('Tracks');
    setState(() {
      tracks = data;
    });
  }

  Future<void> addTrack() async {
    final name = _trackNameController.text;
    final number = int.tryParse(_trackNumberController.text) ?? 0;

    if (name.isEmpty || number == 0) return;

    final db = await DatabaseHelper.instance.database;
    await db.insert('Tracks', {
      'track_name': name,
      'track_number': number,
    });

    _trackNameController.clear();
    _trackNumberController.clear();
    fetchTracks();
  }

  void openParticipantScoreEntry(int trackId, String trackName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParticipantScoreEntryScreen(trackId: trackId, trackName: trackName),
      ),
    );
  }

  void finishTracking() {
    Navigator.pushNamed(context, '/rankings'); // Assuming RankingsScreen is routed as '/rankings'
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tracks', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _trackNameController,
                  decoration: InputDecoration(labelText: 'Track Name'),
                ),
                TextField(
                  controller: _trackNumberController,
                  decoration: InputDecoration(labelText: 'Track Number'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: addTrack,
                      icon: Icon(Icons.add),
                      label: Text('Add Track'),
                    ),
                    ElevatedButton.icon(
                      onPressed: finishTracking,
                      icon: Icon(Icons.done),
                      label: Text('Finish'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                return ListTile(
                  title: Text('${track['track_name']} (Track ${track['track_number']})'),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () =>
                      openParticipantScoreEntry(track['id'], track['track_name']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ParticipantScoreEntryScreen extends StatefulWidget {
  final int trackId;
  final String trackName;

  ParticipantScoreEntryScreen({required this.trackId, required this.trackName});

  @override
  _ParticipantScoreEntryScreenState createState() => _ParticipantScoreEntryScreenState();
}

class _ParticipantScoreEntryScreenState extends State<ParticipantScoreEntryScreen> {
  List<Map<String, dynamic>> participants = [];

  int parseTime(String timeStr) {
  final parts = timeStr.split(':');
  if (parts.length != 3) return 0;
  final minutes = int.tryParse(parts[0]) ?? 0;
  final seconds = int.tryParse(parts[1]) ?? 0;
  final millis = int.tryParse(parts[2]) ?? 0;
  return (minutes * 60000) + (seconds * 1000) + millis;
}
  final Map<int, TextEditingController> timeControllers = {};
  final Map<int, TextEditingController> scoreControllers = {};
  final Map<int, TextEditingController> penaltyControllers = {};

  @override
  void initState() {
    super.initState();
    fetchParticipants();
  }

  void fetchParticipants() async {
    List<Map<String, dynamic>> data = await DatabaseHelper.instance.getAllParticipants();
    setState(() {
      participants = data;
      for (var participant in participants) {
        timeControllers[participant['id']] = TextEditingController();
        scoreControllers[participant['id']] = TextEditingController();
        penaltyControllers[participant['id']] = TextEditingController();
      }
    });
  }

  void submitScores() async {
    for (var participant in participants) {
      int id = participant['id'];
      double time = parseTime(timeControllers[id]?.text ?? '00:00:000').toDouble();
      int score = int.tryParse(scoreControllers[id]?.text ?? '0') ?? 0;
      int penalty = int.tryParse(penaltyControllers[id]?.text ?? '0') ?? 0;

      await DatabaseHelper.instance.insertScore(id, widget.trackId, time, score, penalty);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scores for ${widget.trackName}', style: GoogleFonts.poppins()),
      ),
      body: participants.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final p = participants[index];
                return Card(
                  margin: EdgeInsets.all(10),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p['participant_number']} - ${p['driver_name']}',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        TextField(
                          controller: timeControllers[p['id']],
                          keyboardType: TextInputType.datetime,
                          decoration: InputDecoration(labelText: 'Time (mm:ss:SSS)'),
                        ),
                        TextField(
                          controller: scoreControllers[p['id']],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Track Score'),
                        ),
                        TextField(
                          controller: penaltyControllers[p['id']],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Penalty'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: submitScores,
        label: Text("Submit Scores"),
        icon: Icon(Icons.check),
        backgroundColor: Colors.green,
      ),
    );
  }
}
