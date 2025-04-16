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
      onUpgrade: (db, oldVersion, newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE Tracks ADD COLUMN submitted INTEGER DEFAULT 0');
    }
    },
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
      track_number INTEGER UNIQUE NOT NULL,
      track_name TEXT NOT NULL,
      submitted INTEGER DEFAULT 0
      )''');

    await db.execute('''
      CREATE TABLE Scores(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        participant_id INTEGER NOT NULL,
        track_id INTEGER NOT NULL,
        completion_time REAL NOT NULL,
        track_score INTEGER NOT NULL,
        penalty INTEGER DEFAULT 0,
        FOREIGN KEY (participant_id) REFERENCES Participants(id),
        FOREIGN KEY (track_id) REFERENCES Tracks(id),
        UNIQUE (participant_id, track_id)
      )''');


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
Future<void> insertScore(
    int participantId, int trackId, double time, int score, int penalty) async {
  final db = await instance.database;
  await db.insert(
    'Scores',
    {
      'participant_id': participantId,
      'track_id': trackId,
      'completion_time': time,
      'track_score': score,
      'penalty': penalty,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
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

    //Insert Tracks
  Future<void> insertTrack(int trackNumber,String trackName) async {
    final db = await database;
    await db.insert(
      'Tracks',
      {
        'track_number': trackNumber,
        'track_name': trackName,
        'submitted': 0, // Default value
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

    // Method to delete a track by its ID
    Future<int> deleteTrack(int trackId) async {
      final db = await instance.database;

      return await db.delete(
        'tracks', // Table name
        where: 'id = ?', // Column to match
        whereArgs: [trackId], // Argument for where clause
      );
    }

  //Function to mark track as submitted
  Future<void> markTrackAsSubmitted(int trackId) async {
    final db = await instance.database;
    await db.update(
      'Tracks',
      {'submitted': 1},
      where: 'id = ?',
      whereArgs: [trackId],
    );
  }

  //Get all Tracks
  Future<List<Map<String, dynamic>>> getAllTracks() async {
    final db = await database;
    return await db.query('tracks', orderBy: 'id ASC');
  }



  //Get Participants By Category
  Future<List<Map<String, dynamic>>> getParticipantsByCategory(String category) async {
  final db = await database;

  if (category == 'All Category') {
    return await db.query('Participants');
  } else {
    return await db.query(
      'Participants',
      where: 'category = ?',
      whereArgs: [category],
    );
  }
}

Future close() async {
  final db = await instance.database;
  db.close();
}


}