import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_helper.dart';

class TrackScreen extends StatefulWidget {
  @override
  _TrackScreenState createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  List<Map<String, dynamic>> tracks = [];
  List<String> categories = ['All Category', 'Category 1', 'Category 2']; // Add your actual categories
  String selectedCategory = 'All Category';

  @override
  void initState() {
    super.initState();
    fetchTracks();
  }

  void fetchTracks() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query('Tracks', orderBy: 'track_number ASC');
    setState(() {
      tracks = data;
    });
  }

  Future<void> addTrack() async {
    final nextTrackNumber = tracks.length + 1;
    final name = 'Track $nextTrackNumber';

    final db = await DatabaseHelper.instance.database;
    await db.insert('Tracks', {
      'track_name': name,
      'track_number': nextTrackNumber,
    });

    fetchTracks();
  }

  void openParticipantScoreEntry(int trackId, String trackName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParticipantScoreEntryScreen(
          trackId: trackId,
          trackName: trackName,
          category: selectedCategory,
        ),
      ),
    );
  }

  void finishTracking() {
    Navigator.pushNamed(context, '/rankings');
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
                DropdownButton<String>(
                  value: selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: finishTracking,
                  icon: Icon(Icons.done),
                  label: Text('Submit'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
                  onTap: () => openParticipantScoreEntry(track['id'], track['track_name']),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addTrack,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
        tooltip: 'Add Track',
      ),
    );
  }
}

class ParticipantScoreEntryScreen extends StatefulWidget {
  final int trackId;
  final String trackName;
  final String category;

  ParticipantScoreEntryScreen({
    required this.trackId,
    required this.trackName,
    required this.category,
  });

  @override
  _ParticipantScoreEntryScreenState createState() =>
      _ParticipantScoreEntryScreenState();
}

class _ParticipantScoreEntryScreenState extends State<ParticipantScoreEntryScreen> {
  List<Map<String, dynamic>> participants = [];
  final Map<int, TextEditingController> timeControllers = {};
  final Map<int, TextEditingController> scoreControllers = {};
  final Map<int, TextEditingController> penaltyControllers = {};

  @override
  void initState() {
    super.initState();
    fetchParticipants();
  }

  void fetchParticipants() async {
    List<Map<String, dynamic>> data;
    if (widget.category == 'All Category') {
      data = await DatabaseHelper.instance.getAllParticipants();
    } else {
      data = await DatabaseHelper.instance.getParticipantsByCategory(widget.category);
    }

    setState(() {
      participants = data;
      for (var p in participants) {
        timeControllers[p['id']] = TextEditingController();
        scoreControllers[p['id']] = TextEditingController();
        penaltyControllers[p['id']] = TextEditingController();
      }
    });
  }

  int parseTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 3) return 0;
    final minutes = int.tryParse(parts[0]) ?? 0;
    final seconds = int.tryParse(parts[1]) ?? 0;
    final millis = int.tryParse(parts[2]) ?? 0;
    return (minutes * 60000) + (seconds * 1000) + millis;
  }

  void submitScores() async {
    for (var p in participants) {
      int id = p['id'];
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
