import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();
  
  Future<Database> get database async{
    if(_database != null) return _database!;
    _database = await _initDB ('offroad_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async{
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );    
  }

  // Create Tables
  Future<void> _createDB(Database db, int version) async{
    await db.execute('''
      CREATE TABLE Participants(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      participant_number INTEGER UNIQUE NOT NULL,
      driver_name TEXT NOT NULL,
      co_driver_name TEXT NOT NULL,
      category TEXT NOT NULL)''');

    await db.execute('''
      CREATE TABLE Tracks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        track_name TEXT NOT NULL,
        track_number INTEGER UNIQUE NOT NULL)''');

    await db.execute('''
      CREATE TABLE Scores(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      participant_id INTEGER NOT NULL,
      track_id INTEGER NOT NULL,
      completion_time REAL NOT NULL,
      track_score INTEGER NOT NULL,
      penalty INTEGER DEFAULT 0,
      FOREIGN KEY (participant_id) REFERENCES Participants (id) ON DELETE CASCADE,
      FOREIGN KEY (track_id) REFERENCES Tracks (id) ON DELETE CASCADE)''');

    await db.execute('''
      CREATE TABLE Rankings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        participant_id INTEGER NOT NULL,
        total_score INTEGER NOT NULL,
        rank INTEGER NOT NULL,
        FOREIGN KEY (participant_id) REFERENCES Participants (id) ON DELETE CASCADE)''');
  }


  // Insert Data
  Future<int> insertParticipant(Map<String, dynamic> participant) async{
    final db = await instance.database;
    return await db.insert('Participants', participant);
  } 

// Insert Score Data
Future<int> insertScore(int participantId, int trackId, double completionTime, int trackScore, int penalty) async {
  final db = await instance.database;
  return await db.insert('Scores', {
    'participant_id': participantId,
    'track_id': trackId,
    'completion_time': completionTime,
    'track_score': trackScore,
    'penalty': penalty,
  });
}

// Get Total Scores
Future<List<Map<String, dynamic>>> getTotalScores() async {
  final db = await instance.database;
  return await db.rawQuery('''
    SELECT participant_id, SUM(track_score - penalty - completion_time) AS total_score
    FROM Scores 
    GROUP BY participant_id
    ORDER BY total_score DESC;
  ''');
}

// Get Rankings
Future<List<Map<String, dynamic>>> getRankings() async {
  final db = await instance.database;
  return await db.rawQuery('''
    SELECT participant_id, 
           RANK() OVER (ORDER BY SUM(track_score - penalty - completion_time) DESC) AS rank
    FROM Scores 
    GROUP BY participant_id;
  ''');
}


  // Get All Participants
  Future<List<Map<String, dynamic>>> getAllParticipants() async{
    final db = await instance.database;
    return await db.query('Participants');
  }

  // Delete a Participant
  Future<int> deleteParticipant(int id) async{
    final db = await instance.database;
    return await db.delete('Participants', where: 'id = ?', whereArgs: [id]);
  }


}