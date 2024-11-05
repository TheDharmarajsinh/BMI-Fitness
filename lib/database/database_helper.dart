import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/bmi_record.dart';
import '../models/bmi_goal.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }
  // Add this method to DatabaseHelper
  Future<void> deleteBmiRecord(int id) async {
    final db = await database;
    await db.delete(
      'bmiHistory',
      where: 'id = ?',   // Use id to identify the specific record
      whereArgs: [id],    // Provide the id of the record to delete
    );
  }


  Future<Database> _initDb() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'bmi_calculator.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''  
          CREATE TABLE bmiHistory(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bmi REAL,
            height REAL,
            weight REAL,
            date TEXT
          )
        ''');
        await db.execute('''  
          CREATE TABLE bmiGoals(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            targetBmi REAL,
            date TEXT
          )
        ''');
      },
    );
  }

  // BMI Record Methods
  Future<void> insertBmiRecord(BmiRecord record) async {
    final db = await database;
    await db.insert('bmiHistory', record.toMap());
  }

  Future<List<BmiRecord>> getBmiHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('bmiHistory', orderBy: 'date DESC');
    return List.generate(maps.length, (i) {
      return BmiRecord(
        id: maps[i]['id'],
        bmi: maps[i]['bmi'],
        height: maps[i]['height'],
        weight: maps[i]['weight'],
        date: maps[i]['date'],
      );
    });
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('bmiHistory'); // Deletes all records in the table
  }

  // BMI Goal Methods
  Future<void> insertBmiGoal(BmiGoal goal) async {
    final db = await database;
    await db.insert('bmiGoals', goal.toMap());
  }

  Future<List<BmiGoal>> getBmiGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('bmiGoals', orderBy: 'date DESC');
    return List.generate(maps.length, (i) {
      return BmiGoal(
        id: maps[i]['id'],
        targetBmi: maps[i]['targetBmi'],
        date: maps[i]['date'],
      );
    });
  }

  Future<void> updateBmiGoal(BmiGoal goal) async {
    final db = await database;
    await db.update(
      'bmiGoals',
      goal.toMap(), // Convert the BmiGoal object to a Map
      where: 'id = ?', // Identify the record to update
      whereArgs: [goal.id], // Use the ID of the goal to update
    );
  }

  Future<void> clearGoals() async {
    final db = await database;
    await db.delete('bmiGoals'); // Deletes all records in the table
  }
}
