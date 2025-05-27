import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/policy.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = await getDatabasesPath();
    String databasePath = join(path, 'garg_insurance.db');
    return await openDatabase(
      databasePath,
      version: 2, // Increment database version
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Add onUpgrade callback
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE policies(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        policyType TEXT NOT NULL,
        autoPolicySubType TEXT,
        policyCompany TEXT,
        policyStartDate TEXT,
        vehicleNumber TEXT,
        customerName TEXT NOT NULL,
        contactNumber TEXT NOT NULL,
        coverageAmount REAL NOT NULL,
        premiumDueDate TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for version 2
      await db.execute('ALTER TABLE policies ADD COLUMN autoPolicySubType TEXT;');
      await db.execute('ALTER TABLE policies ADD COLUMN policyCompany TEXT;');
      await db.execute('ALTER TABLE policies ADD COLUMN policyStartDate TEXT;');
    }
  }

  Future<int> insertPolicy(Policy policy) async {
    Database db = await database;
    return await db.insert('policies', policy.toMap());
  }

  Future<List<Policy>> getPolicies() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('policies');
    return List.generate(maps.length, (i) {
      return Policy.fromMap(maps[i]);
    });
  }

  Future<int> updatePolicy(Policy policy) async {
    Database db = await database;
    return await db.update(
      'policies',
      policy.toMap(),
      where: 'id = ?',
      whereArgs: [policy.id],
    );
  }

  Future<int> deletePolicy(int id) async {
    Database db = await database;
    return await db.delete(
      'policies',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Policy>> searchPolicies(String query) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'policies',
      where: 'customerName LIKE ? OR vehicleNumber LIKE ? OR policyType LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) {
      return Policy.fromMap(maps[i]);
    });
  }
}
