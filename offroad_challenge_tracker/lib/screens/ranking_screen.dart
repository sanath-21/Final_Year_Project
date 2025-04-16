import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class RankingScreen extends StatefulWidget {
  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<Map<String, dynamic>> participants = [];
  List<Map<String, dynamic>> tracks = [];
  String selectedCategory = 'All Category';
  String selectedTrack = 'All Tracks';
  List<String> categories = ['All Category'];
  List<String> trackNames = ['All Tracks'];

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    final db = await DatabaseHelper.instance.database;

    // Load tracks
    final tracksData = await db.query('Tracks', orderBy: 'track_number ASC');
    tracks = tracksData;
    trackNames = ['All Tracks'] + tracks.map((t) => t['track_name'] as String).toList();

    // Load categories
    final categoryData = await db.rawQuery('SELECT DISTINCT category FROM Participants');
    final catList = categoryData
        .map((e) => e['category'] as String)
        .where((e) => e.isNotEmpty)
        .toList();
    categories = ['All Category'] + catList;

    await fetchParticipants();
  }

  Future<void> fetchParticipants() async {
    final db = await DatabaseHelper.instance.database;

    String query = '''
      SELECT p.id, p.participant_number, p.driver_name, p.co_driver_name, p.category,
             s.track_id, s.time, s.score, s.penalty
      FROM Participants p
      LEFT JOIN Scores s ON p.id = s.participant_id
    ''';

    final raw = await db.rawQuery(query);

    final Map<int, Map<String, dynamic>> grouped = {};

    for (var row in raw) {
      final id = row['id'] as int;

      grouped.putIfAbsent(id, () => {
            'id': id,
            'participant_number': row['participant_number'],
            'driver_name': row['driver_name'],
            'co_driver_name': row['co_driver_name'],
            'category': row['category'],
            'tracks': {},
            'total_score': 0,
          });

      if (row['track_id'] != null) {
        final int tid = row['track_id'] as int;
        final double time = (row['time'] as num).toDouble();
        final int score = row['score'] as int;
        final int penalty = row['penalty'] as int;
        final int net = score - penalty;

        grouped[id]!['tracks'][tid] = {
          'time': time,
          'score': score,
          'penalty': penalty,
          'net': net,
        };

        grouped[id]!['total_score'] += net;
      }
    }

    List<Map<String, dynamic>> sorted = grouped.values.toList();

    // Filter by category
    if (selectedCategory != 'All Category') {
      sorted = sorted.where((p) => p['category'] == selectedCategory).toList();
    }

    // Sort by total score descending
    sorted.sort((a, b) => (b['total_score'] as int).compareTo(a['total_score'] as int));

    setState(() {
      participants = sorted;
    });
  }

  String formatTime(double millis) {
    final duration = Duration(milliseconds: millis.toInt());
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (duration.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$minutes:$seconds:$ms';
  }

  Widget buildTable() {
    final List<DataRow> rows = [];

    for (int i = 0; i < participants.length; i++) {
      final p = participants[i];

      String timeStr = '-', scoreStr = '-', posStr = '-', penaltyStr = '-', netStr = '-';

      if (selectedTrack != 'All Tracks') {
        final track = tracks.firstWhere(
          (t) => t['track_name'] == selectedTrack,
          orElse: () => {},
        );

        final tid = track['id'];
        final trackData = (p['tracks'] as Map)[tid];

        if (trackData != null) {
          timeStr = formatTime(trackData['time']);
          scoreStr = trackData['score'].toString();
          penaltyStr = trackData['penalty'].toString();
          netStr = trackData['net'].toString();

          int pos = participants
              .where((q) => (q['tracks'][tid]?['net'] ?? 0) > trackData['net'])
              .length +
              1;
          posStr = pos.toString();
        }
      }

      rows.add(DataRow(cells: [
        DataCell(Text('${p['participant_number']}')),
        DataCell(Text(p['driver_name'])),
        DataCell(Text(p['co_driver_name'])),
        DataCell(Text(p['category'])),
        DataCell(Text(timeStr)),
        DataCell(Text(posStr)),
        DataCell(Text(scoreStr)),
        DataCell(Text(penaltyStr)),
        DataCell(Text(netStr)),
        DataCell(Text('${p['total_score']}')),
        DataCell(Text('${i + 1}')),
      ]));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(columns: [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Driver')),
        DataColumn(label: Text('Co-Driver')),
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('Time')),
        DataColumn(label: Text('Position')),
        DataColumn(label: Text('Score')),
        DataColumn(label: Text('Penalty')),
        DataColumn(label: Text('Net')),
        DataColumn(label: Text('Total')),
        DataColumn(label: Text('Rank')),
      ], rows: rows),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rankings'),
        actions: [
          DropdownButton<String>(
            value: selectedCategory,
            onChanged: (val) {
              setState(() => selectedCategory = val!);
              fetchParticipants();
            },
            items: categories
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
          ),
          DropdownButton<String>(
            value: selectedTrack,
            onChanged: (val) {
              setState(() => selectedTrack = val!);
              fetchParticipants();
            },
            items: trackNames
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
          ),
        ],
      ),
      body: participants.isEmpty
          ? Center(child: Text('No participants to display.'))
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: buildTable(),
            ),
    );
  }
}
