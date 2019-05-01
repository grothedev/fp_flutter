import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

void saveCroaks(croaks) async{
  var c = [];

  final Future<Database> dbFuture = openDatabase(
    join(await getDatabasesPath(), 'fp.db'),
    onCreate: (db, v){
      db.execute('CREATE TABLE croaks(id INTEGER PRIMARY KEY, timestamp DATE, content TEXT, score INTEGER, tags TEXT)');
    },
    version: 1
  );
  final Database db = await dbFuture;

  for (int i = 0; i < croaks.length; i++){
    c.add(Croak(id: croaks[i]['id'], content: croaks[i]['content'], timestamp: croaks[i]['timestamp'], tags: croaks[i]['tags'], score: croaks[i]['score']));
    db.insert('croaks', c[i].toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
}

Future<List> loadCroaks() async{
  //TODO load croaks from disk
  return null;
}