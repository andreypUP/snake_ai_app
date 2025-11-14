import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:venom_shield_ph/domain/models/classification_report.dart';

@singleton
class ClassificationDbService {
  Database? _database;

  static const String _tableName = 'classification_reports';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'venom_shield.db');

    return await openDatabase(
      path,
      version: 2, // Incremented version
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            snakeId TEXT NOT NULL,
            snakeName TEXT NOT NULL,
            scientificName TEXT,
            confidence REAL NOT NULL,
            imageLocalPath TEXT NOT NULL,
            imageUrl TEXT,
            snakeInfo TEXT NOT NULL,
            dateClassified TEXT NOT NULL,
            isSynced INTEGER NOT NULL DEFAULT 0,
            syncedAt TEXT,
            sharedAsSnakeReport INTEGER NOT NULL DEFAULT 0,
            sharedReportId TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add new columns for existing database
          await db.execute('ALTER TABLE $_tableName ADD COLUMN snakeId TEXT DEFAULT ""');
          await db.execute('ALTER TABLE $_tableName ADD COLUMN snakeInfo TEXT DEFAULT "{}"');
          await db.execute('ALTER TABLE $_tableName ADD COLUMN syncedAt TEXT');
          await db.execute('ALTER TABLE $_tableName ADD COLUMN sharedAsSnakeReport INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE $_tableName ADD COLUMN sharedReportId TEXT');
        }
      },
    );
  }

  Future<String> insertClassificationReport(ClassificationReport report) async {
    final db = await database;
    await db.insert(
      _tableName,
      {
        'id': report.id,
        'userId': report.userId,
        'snakeId': report.snakeId,
        'snakeName': report.snakeName,
        'scientificName': report.scientificName,
        'confidence': report.confidence,
        'imageLocalPath': report.imageLocalPath,
        'imageUrl': report.imageUrl,
        'snakeInfo': _encodeJson(report.snakeInfo),
        'dateClassified': report.dateClassified.toIso8601String(),
        'isSynced': report.isSynced ? 1 : 0,
        'syncedAt': report.syncedAt?.toIso8601String(),
        'sharedAsSnakeReport': report.sharedAsSnakeReport ? 1 : 0,
        'sharedReportId': report.sharedReportId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return report.id;
  }

  String _encodeJson(Map<String, dynamic> json) {
    return jsonEncode(json);
  }

  Map<String, dynamic> _decodeJson(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<List<ClassificationReport>> getClassificationReportsByUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dateClassified DESC',
    );

    return List.generate(maps.length, (i) {
      return ClassificationReport(
        id: maps[i]['id'],
        userId: maps[i]['userId'],
        snakeId: maps[i]['snakeId'] ?? '',
        snakeName: maps[i]['snakeName'],
        scientificName: maps[i]['scientificName'],
        confidence: maps[i]['confidence'],
        imageLocalPath: maps[i]['imageLocalPath'],
        imageUrl: maps[i]['imageUrl'],
        snakeInfo: _decodeJson(maps[i]['snakeInfo'] ?? '{}'),
        dateClassified: DateTime.parse(maps[i]['dateClassified']),
        isSynced: maps[i]['isSynced'] == 1,
        syncedAt: maps[i]['syncedAt'] != null
            ? DateTime.parse(maps[i]['syncedAt'])
            : null,
        sharedAsSnakeReport: maps[i]['sharedAsSnakeReport'] == 1,
        sharedReportId: maps[i]['sharedReportId'],
      );
    });
  }

  Future<List<ClassificationReport>> getUnsyncedReports(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'userId = ? AND isSynced = 0',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) {
      return ClassificationReport(
        id: maps[i]['id'],
        userId: maps[i]['userId'],
        snakeId: maps[i]['snakeId'] ?? '',
        snakeName: maps[i]['snakeName'],
        scientificName: maps[i]['scientificName'],
        confidence: maps[i]['confidence'],
        imageLocalPath: maps[i]['imageLocalPath'],
        imageUrl: maps[i]['imageUrl'],
        snakeInfo: _decodeJson(maps[i]['snakeInfo'] ?? '{}'),
        dateClassified: DateTime.parse(maps[i]['dateClassified']),
        isSynced: maps[i]['isSynced'] == 1,
        syncedAt: maps[i]['syncedAt'] != null
            ? DateTime.parse(maps[i]['syncedAt'])
            : null,
        sharedAsSnakeReport: maps[i]['sharedAsSnakeReport'] == 1,
        sharedReportId: maps[i]['sharedReportId'],
      );
    });
  }

  Future<void> updateClassificationReport(ClassificationReport report) async {
    final db = await database;
    await db.update(
      _tableName,
      {
        'snakeId': report.snakeId,
        'snakeName': report.snakeName,
        'scientificName': report.scientificName,
        'confidence': report.confidence,
        'imageUrl': report.imageUrl,
        'snakeInfo': _encodeJson(report.snakeInfo),
        'isSynced': report.isSynced ? 1 : 0,
        'syncedAt': report.syncedAt?.toIso8601String(),
        'sharedAsSnakeReport': report.sharedAsSnakeReport ? 1 : 0,
        'sharedReportId': report.sharedReportId,
      },
      where: 'id = ?',
      whereArgs: [report.id],
    );
  }

  Future<void> markAsSynced(String id, String imageUrl) async {
    final db = await database;
    await db.update(
      _tableName,
      {
        'isSynced': 1,
        'imageUrl': imageUrl,
        'syncedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteClassificationReport(String id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<ClassificationReport?> getClassificationReportById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return ClassificationReport(
      id: maps[0]['id'],
      userId: maps[0]['userId'],
      snakeId: maps[0]['snakeId'] ?? '',
      snakeName: maps[0]['snakeName'],
      scientificName: maps[0]['scientificName'],
      confidence: maps[0]['confidence'],
      imageLocalPath: maps[0]['imageLocalPath'],
      imageUrl: maps[0]['imageUrl'],
      snakeInfo: _decodeJson(maps[0]['snakeInfo'] ?? '{}'),
      dateClassified: DateTime.parse(maps[0]['dateClassified']),
      isSynced: maps[0]['isSynced'] == 1,
      syncedAt: maps[0]['syncedAt'] != null
          ? DateTime.parse(maps[0]['syncedAt'])
          : null,
      sharedAsSnakeReport: maps[0]['sharedAsSnakeReport'] == 1,
      sharedReportId: maps[0]['sharedReportId'],
    );
  }
}
