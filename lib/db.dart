import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

Database database;

void initDB() async{
  openDatabase(
    join(await getDatabasesPath(), 'fp.db'),
    onCreate: (db, v){
      //NOTE: the PK ids on these tables are not the same as on server
      db.execute('CREATE TABLE croaks(id INTEGER PRIMARY KEY, timestamp TEXT, content TEXT, score INTEGER, tags TEXT, type INTEGER, x REAL, y REAL)');
      //db.execute('CREATE TABLE prefs()'); //use shared prefs, but maybe saved tags/users could be saved here because there could be a lot
      //db.execute('CREATE TABLE tags(id INTEGER PRIMARY KEY, label TEXT)');
      //db.execute('CREATE TABLE croaks_tags(croak_id INTEGER, tag_id INTEGER)');
    },
    version: 1
  ).then((db){
    database = db;
  });
}

void saveCroaks(croaks) async{
  
  
  for (int i = 0; i < croaks.length; i++){
    var c = croaks[i];
    var tags = "";
    for (int j = 0; j < c['tags'].length; j++){
      tags += c['tags'][j]['label'] + ",";
    }
    //something feels wrong about this. i should make a fromMap() function 
    //c.add(Croak(id: croaks[i]['id'], content: croaks[i]['content'], timestamp: croaks[i]['timestamp'], tags: croaks[i]['tags'], score: croaks[i]['score']));
    
    print('saving: ' + croaks[i].toString());
    database.insert('croaks', {
      'id': c['id'],
      'timestamp': c['created_at'],
      'content': c['content'],
      'score': c['score'],
      'tags': tags, 
      'x': c['x'],
      'y': c['y'],
      'type': c['type']
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    
  }
  
}

Future<List> loadCroaks() async{
  return await database.query('croaks');
}

void saveTags(tags) async{

}

Future<List> loadTags() async{

}
