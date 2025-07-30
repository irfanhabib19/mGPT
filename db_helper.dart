import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> getDB() async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), "history.db"),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE history(id INTEGER PRIMARY KEY AUTOINCREMENT, prompt TEXT, response TEXT, type TEXT)",
        );
      },
      version: 1,
    );
    return _db!;
  }

  static Future<void> insertHistory(
    String prompt,
    String response,
    String type,
  ) async {
    final db = await getDB();
    await db.insert("history", {
      "prompt": prompt,
      "response": response,
      "type": type,
    });
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final db = await getDB();
    return db.query("history", orderBy: "id DESC");
  }

  static Future<void> deleteHistory(int id) async {
    final db = await getDB();
    await db.delete("history", where: "id = ?", whereArgs: [id]);
  }
}
