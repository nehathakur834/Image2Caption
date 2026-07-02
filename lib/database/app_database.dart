import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/caption_record.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'caption_history.db');

    _database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE captions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            image_path TEXT NOT NULL,
            caption TEXT NOT NULL,
            hashtags TEXT NOT NULL,
            tone TEXT,
            platform TEXT,
            language TEXT NOT NULL DEFAULT 'english',
            analysis_summary TEXT NOT NULL DEFAULT '',
            timestamp TEXT NOT NULL,
            is_favorite INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE captions ADD COLUMN language TEXT NOT NULL DEFAULT 'english'",
          );
          await db.execute(
            "ALTER TABLE captions ADD COLUMN analysis_summary TEXT NOT NULL DEFAULT ''",
          );
        }
      },
    );

    return _database!;
  }

  Future<List<CaptionRecord>> fetchCaptions() async {
    final db = await database;
    final maps = await db.query('captions', orderBy: 'timestamp DESC');

    return maps.map(CaptionRecord.fromMap).toList();
  }

  Future<int> insertCaption(CaptionRecord record) async {
    final db = await database;
    return db.insert('captions', record.toMap());
  }

  Future<void> updateCaption(CaptionRecord record) async {
    final db = await database;
    await db.update(
      'captions',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> deleteCaption(int id) async {
    final db = await database;
    await db.delete('captions', where: 'id = ?', whereArgs: [id]);
  }
}
