import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_helper.dart';

class ParticipantScoreEntryScreen extends StatefulWidget {
  final int trackId;
  final String trackName;

  const ParticipantScoreEntryScreen({
    Key? key,
    required this.trackId,
    required this.trackName,
  }) : super(key: key);

  @override
  _ParticipantScoreEntryScreenState createState() =>
      _ParticipantScoreEntryScreenState();
}

class _ParticipantScoreEntryScreenState
    extends State<ParticipantScoreEntryScreen> {
  List<Map<String, dynamic>> participants = [];
  List<String> categories = [
    'All Category',
    'All Stock',
    'Mod Petrol',
    'Mod Diesel',
    'Pro',
    'Ladies + Pro'
  ];
  String selectedCategory = 'All Category';
  bool isTrackSubmitted = false;

  final Map<int, TextEditingController> timeControllers = {};
  final Map<int, TextEditingController> scoreControllers = {};
  final Map<int, TextEditingController> penaltyControllers = {};
  final Map<int, bool> dnfFlags = {};
  final Map<int, bool> isExpanded = {};

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    initializeScreen();
  }

  @override
  void dispose() {
    timeControllers.forEach((_, c) => c.dispose());
    scoreControllers.forEach((_, c) => c.dispose());
    penaltyControllers.forEach((_, c) => c.dispose());

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> initializeScreen() async {
    final db = await DatabaseHelper.instance.database;
    final track = await db.query('Tracks', where: 'id = ?', whereArgs: [widget.trackId]);

    if (track.isNotEmpty && track.first['is_completed'] == 1) {
      isTrackSubmitted = true;
    }

    await loadCategories();
    await fetchParticipants();
    setState(() {});
  }

  Future<void> loadCategories() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('SELECT DISTINCT category FROM Participants');
    final loaded = result.map((e) => e['category'].toString()).toList();
    categories = ['All Category'] + loaded;
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
      final existing = await db.query(
        'Scores',
        where: 'participant_id = ? AND track_id = ?',
        whereArgs: [id, widget.trackId],
      );

      final isDNF = existing.isNotEmpty && existing.first['time'] == 0;
      dnfFlags[id] = isDNF;
      isExpanded[id] = false;

      final timeText = existing.isNotEmpty && existing.first['time'] != null
          ? (existing.first['time'] != 0
              ? formatTime((existing.first['time'] as num).toDouble())
              : '')
          : '';
      final scoreText = existing.isNotEmpty ? existing.first['score'].toString() : '';
      final penaltyText = existing.isNotEmpty ? existing.first['penalty'].toString() : '0';

      timeControllers[id]?.dispose();
      scoreControllers[id]?.dispose();
      penaltyControllers[id]?.dispose();

      timeControllers[id] = TextEditingController(text: timeText);
      scoreControllers[id] = TextEditingController(text: scoreText);
      penaltyControllers[id] = TextEditingController(text: penaltyText);
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

  int calculateTotalScore(int id) {
  if (dnfFlags[id] == true) {
    return 20;
  }

  final scoreStr = scoreControllers[id]?.text ?? '';
  final penaltyStr = penaltyControllers[id]?.text ?? '';

  final score = int.tryParse(scoreStr);
  final penalty = int.tryParse(penaltyStr);

  if (score == null || penalty == null) {
    return 0; // Or return null and show '-' in UI
  }

  final total = score - penalty;
  return total >= 0 ? total : 0; // Prevent negative total
}




  Future<void> submitButton() async {
    if (isTrackSubmitted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Submission'),
        content: Text('Submit all scores? You cannot make changes later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Submit')),
        ],
      ),
    );

    if (confirm != true) return;

    final db = await DatabaseHelper.instance.database;

    // Submit Scores for each participant
    for (var p in participants) {
      final id = p['id'];
      final timeStr = timeControllers[id]?.text.trim() ?? '';
      final scoreStr = scoreControllers[id]?.text.trim() ?? '';
      final penaltyStr = penaltyControllers[id]?.text.trim() ?? '0';

      final isIncomplete = timeStr.isEmpty || scoreStr.isEmpty;
      final dnf = dnfFlags[id] == true || isIncomplete;

      final time = dnf ? 0.0 : parseTime(timeStr).toDouble();
      final score = dnf ? 20 : int.tryParse(scoreStr) ?? 0;
      final penalty = dnf ? 0 : int.tryParse(penaltyStr) ?? 0;

      await DatabaseHelper.instance.insertScore(id, widget.trackId, time, score, penalty);
    }

    // Mark the track as submitted
    await db.update('Tracks', {'submitted': 1}, where: 'id = ?', whereArgs: [widget.trackId]);

    setState(() => isTrackSubmitted = true);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scores submitted.')));
    Navigator.pop(context); // Return to Track Screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trackName, style: GoogleFonts.poppins()),
        actions: [
          if (!isTrackSubmitted)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: DropdownButton<String>(
                value: selectedCategory,
                underline: SizedBox(),
                onChanged: (value) async {
                  setState(() => selectedCategory = value!);
                  await fetchParticipants();
                },
                items: categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
              ),
            ),
        ],
      ),
      body: participants.isEmpty
          ? Center(child: Text('No participants found.'))
          : ListView(
              padding: EdgeInsets.all(10),
              children: participants.map((p) {
                final id = p['id'];
                final isDisabled = isTrackSubmitted;

                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    title: Text(
                      '${p['participant_number']} - ${p['driver_name']}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    children: [
                      CheckboxListTile(
                        value: dnfFlags[id] ?? false,
                        onChanged: isDisabled ? null : (val) => setState(() => dnfFlags[id] = val!),
                        title: Text('DNF (Score = 20)', style: GoogleFonts.poppins()),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (!(dnfFlags[id] ?? false)) ...[
                        buildInputField(
                          label: 'Time (mm:ss:SSS)',
                          controller: timeControllers[id],
                          enabled: !isDisabled,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                            LengthLimitingTextInputFormatter(9),
                          ],
                        ),
                        buildInputField(
                          label: 'Score',
                          controller: scoreControllers[id],
                          enabled: !isDisabled,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                        buildInputField(
                          label: 'Penalty',
                          controller: penaltyControllers[id],
                          enabled: !isDisabled,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 10),
                        child: Text(
                          'Total Score: ${scoreControllers[id]?.text.isEmpty == true || penaltyControllers[id]?.text.isEmpty == true ? '-' : calculateTotalScore(id)}',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: isTrackSubmitted
          ? null
          : FloatingActionButton.extended(
              onPressed: submitButton,
              label: Text('Submit'),
              icon: Icon(Icons.check),
              backgroundColor: Colors.green.shade600,
            ),
    );
  }

  Widget buildInputField({
    required String label,
    required TextEditingController? controller,
    required bool enabled,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        readOnly: !enabled,
        keyboardType: TextInputType.number,
        inputFormatters: inputFormatters,
      ),
    );
  }
}
