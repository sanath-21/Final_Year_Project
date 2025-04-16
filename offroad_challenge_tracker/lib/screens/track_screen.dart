import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'participant_score_entry_screen.dart';
import 'ranking_screen.dart';

class TrackScreen extends StatefulWidget {
  @override
  _TrackScreenState createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> tracks = [];
  int nextTrackNumber = 1;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadTracks();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTracks() async {
    try {
      final data = await DatabaseHelper.instance.getAllTracks();
      setState(() {
        tracks = data;
        nextTrackNumber = data.length + 1;
      });
    } catch (e) {
      print("Error loading tracks: $e");
    }
  }

  Future<void> _addTrack() async {
    try {
      if (tracks.isNotEmpty && tracks.last['submitted'] == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Submit scores for the current track before adding a new one."),
          ),
        );
        return;
      }

      String name = 'Track $nextTrackNumber';
      await DatabaseHelper.instance.insertTrack(nextTrackNumber, name);
      await _loadTracks();
      _animationController.forward(from: 0); // Restart animation

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Track $name added successfully!")),
      );
    } catch (e) {
      print("Error adding track: $e");
    }
  }

  void _navigateToScoreEntry(Map<String, dynamic> track) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParticipantScoreEntryScreen(
          trackId: track['id'],
          trackName: track['track_name'],
        ),
      ),
    );
    await _loadTracks();
  }

  void _submitAndGoToRankings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RankingScreen(),
      ),
    );
  }

  Future<void> _deleteTrack(int trackId) async {
    try {
      await DatabaseHelper.instance.deleteTrack(trackId);
      await _loadTracks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Track deleted successfully!")),
      );
    } catch (e) {
      print("Error deleting track: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tracks')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _addTrack,
                  icon: Icon(Icons.add),
                  label: Text("Add Track"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton.icon(
                  onPressed: _submitAndGoToRankings,
                  icon: Icon(Icons.check),
                  label: Text("Submit"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ),
          Expanded(
            child: tracks.isEmpty
                ? Center(child: Text('No tracks added yet.'))
                : ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      final isSubmitted = track['submitted'] == 1;

                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Card(
                            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(
                                track['track_name'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSubmitted ? Icons.check_circle : Icons.pending,
                                    color: isSubmitted ? Colors.green : Colors.orange,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      bool deleteTrack = await showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Delete Track'),
                                            content: Text(
                                                'Are you sure you want to delete this track?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(false);
                                                },
                                                child: Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(true);
                                                },
                                                child: Text('Delete'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      if (deleteTrack) {
                                        _deleteTrack(track['id']);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: () => _navigateToScoreEntry(track),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
