import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_helper.dart';
import '../screens/ranking_screen.dart';

class ParticipantScoreEntryScreen extends StatefulWidget {
  final int trackId;
  final String trackName;

  const ParticipantScoreEntryScreen({
    required this.trackId,
    required this.trackName,
  });

  @override
  State<ParticipantScoreEntryScreen> createState() => _ParticipantScoreEntryScreenState();
}

class _ParticipantScoreEntryScreenState extends State<ParticipantScoreEntryScreen> {
  List<Map<String, dynamic>> participants = [];
  List<String> categories = ['All Category'];
  String selectedCategory = 'All Category';
  bool isTrackSubmitted = false;

  final Map<int, TextEditingController> timeControllers = {};
  final Map<int, TextEditingController> scoreControllers = {};
  final Map<int, TextEditingController> penaltyControllers = {};
  final Map<int, bool> dnfFlags = {};

  @override
  void initState() {
    super.initState();
    checkTrackSubmitted();
  }

  Future<void> checkTrackSubmitted() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('Tracks', where: 'id = ?', whereArgs: [widget.trackId]);

    if (result.isNotEmpty && result.first['is_completed'] == 1) {
      setState(() {
        isTrackSubmitted = true;
      });
    }

    if (!isTrackSubmitted) {
      await loadCategories();
      await fetchParticipants();
    } else {
      // If the track is already completed, fetch the existing data
      await fetchParticipants();
    }
  }

  Future<void> loadCategories() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('SELECT DISTINCT category FROM Participants');
    final loaded = result.map((e) => e['category'].toString()).toList();

    setState(() {
      categories = ['All Category'] + loaded;
    });
  }

  Future<void> fetchParticipants() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery(
      selectedCategory == 'All Category'
          ? 'SELECT * FROM Participants'
          : 'SELECT * FROM Participants WHERE category = ?',
      selectedCategory == 'All Category' ? [] : [selectedCategory],
    );

    participants = result;

    for (var p in participants) {
      final id = p['id'];

      final existingScore = await db.query(
        'Scores',
        where: 'participant_id = ? AND track_id = ?',
        whereArgs: [id, widget.trackId],
      );

      final isDNF = existingScore.isNotEmpty && existingScore.first['time'] == 0;

      dnfFlags[id] = isDNF; // Default isDNF or false
      timeControllers[id] = TextEditingController(
        text: (existingScore.isNotEmpty && existingScore.first['time'] != 0)
            ? formatTime(existingScore.first['time'] as double)
            : '',
      );
      scoreControllers[id] = TextEditingController(
        text: existingScore.isNotEmpty ? existingScore.first['score'].toString() : '',
      );
      penaltyControllers[id] = TextEditingController(
        text: existingScore.isNotEmpty ? existingScore.first['penalty'].toString() : '0',
      );

      // Ensure no nulls for checkboxes
      dnfFlags[id] ??= false;
    }

    setState(() {});
  }

  int parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 3) return 0;
      final min = int.parse(parts[0]);
      final sec = int.parse(parts[1]);
      final millis = int.parse(parts[2]);
      return min * 60000 + sec * 1000 + millis;
    } catch (_) {
      return 0;
    }
  }

  String formatTime(double millis) {
    final duration = Duration(milliseconds: millis.toInt());
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (duration.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$minutes:$seconds:$ms';
  }

  Future<void> submitButton() async {
    final db = await DatabaseHelper.instance.database;

    for (var p in participants) {
      final id = p['id'];
      final dnf = dnfFlags[id] ?? false;

      final time = dnf ? 0.0 : parseTime(timeControllers[id]?.text ?? '00:00:000').toDouble();
      final score = dnf ? 0 : int.tryParse(scoreControllers[id]?.text ?? '0') ?? 0;
      final penalty = dnf ? 20 : int.tryParse(penaltyControllers[id]?.text ?? '0') ?? 0;

      await DatabaseHelper.instance.insertScore(id, widget.trackId, time, score, penalty);
    }

    await db.update(
  'Tracks',
  {'is_completed': 1},
  where: 'id = ?',
  whereArgs: [widget.trackId],
);

    setState(() {
      isTrackSubmitted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scores submitted successfully.')));

    // Navigate to the Rankings screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => RankingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trackName),
        actions: [
          DropdownButton<String>(
            value: selectedCategory,
            onChanged: (value) {
              setState(() => selectedCategory = value!);
              fetchParticipants();
            },
            items: categories.map((cat) {
              return DropdownMenuItem<String>(value: cat, child: Text(cat));
            }).toList(),
          ),
        ],
      ),
      body: participants.isEmpty
          ? Center(child: Text('No participants found.'))
          : ListView.builder(
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final p = participants[index];
                final id = p['id'];
                final isReadOnly = isTrackSubmitted;

                // Default to DNF if the field is empty
                if (timeControllers[id]?.text.isEmpty ?? true) {
                  dnfFlags[id] = true;
                }

                return Card(
                  margin: EdgeInsets.all(10),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p['participant_number']} - ${p['driver_name']}',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: dnfFlags[id] ?? false,
                              onChanged: isReadOnly
                                  ? null
                                  : (val) {
                                      setState(() => dnfFlags[id] = val!);
                                    },
                            ),
                            Text('DNF (20 penalty)', style: GoogleFonts.poppins()),
                          ],
                        ),
                        if (!(dnfFlags[id] ?? false)) ...[
                          TextField(
                            controller: timeControllers[id],
                            decoration: InputDecoration(labelText: 'Time (00:00:000)'),
                            readOnly: isReadOnly,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                              LengthLimitingTextInputFormatter(9),
                            ],
                          ),
                          TextField(
                            controller: scoreControllers[id],
                            decoration: InputDecoration(labelText: 'Track Score'),
                            readOnly: isReadOnly,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                          TextField(
                            controller: penaltyControllers[id],
                            decoration: InputDecoration(labelText: 'Penalty'),
                            readOnly: isReadOnly,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: isTrackSubmitted
          ? null
          : FloatingActionButton.extended(
              onPressed: submitButton,
              label: Text('Submit'),
              icon: Icon(Icons.check),
              backgroundColor: Colors.green,
            ),
    );
  }
}
