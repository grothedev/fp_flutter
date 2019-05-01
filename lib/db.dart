import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

Database database;

void initDB() async{
  openDatabase(
    join(await getDatabasesPath(), 'fp.db'),
    onCreate: (db, v){
      db.execute('CREATE TABLE croaks(id INTEGER PRIMARY KEY, timestamp DATE, content TEXT, score INTEGER, tags TEXT)');
      //db.execute('CREATE TABLE prefs()'); //use shared prefs, but maybe saved tags/users could be saved here because there could be a lot
    },
    version: 1
  ).then((db){
    database = db;
  });
}

void saveCroaks(croaks) async{
  
  var c = [];
  for (int i = 0; i < croaks.length; i++){
    //something feels wrong about this. i should make a fromMap() function 
    c.add(Croak(id: croaks[i]['id'], content: croaks[i]['content'], timestamp: croaks[i]['timestamp'], tags: croaks[i]['tags'], score: croaks[i]['score']));
    database.insert('croaks', c[i].toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
}

Future<List> loadCroaks() async{
  return await database.query('croaks');
}