/*
Frog Pond mobile application
Copyright (C) 2019  Thomas Grothe

This file is part of FrogPond.

FrogPond is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

FrogPond is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
*/

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

Database database;

void initDB() async{
  print( await getDatabasesPath());
  openDatabase(
   
    join(await getDatabasesPath(), 'fp.db'),
    onCreate: (db, v){
      //NOTE: the PK ids on these tables are not the same as on server
      db.execute('CREATE TABLE croaks(id INTEGER PRIMARY KEY, p_id INTEGER, created_at TEXT, content TEXT, score INTEGER, tags TEXT, type INTEGER, x REAL, y REAL, listening INTEGER)');
      //db.execute('CREATE TABLE tags(id INTEGER PRIMARY KEY, label TEXT)');
      //db.execute('CREATE TABLE croaks_tags(croak_id INTEGER, tag_id INTEGER)');
    },
    version: 1
  ).then((db){  
    database = db;
  }).catchError((e){
    print('db failed to init');
  });

}

void saveCroaks(croaks) async{  
  
  openDatabase(
    join(await getDatabasesPath(), 'fp.db'),
  ).then((db){
    for (int i = 0; i < croaks.length; i++){
      var c = croaks[i];
      var tags = "";
      for (int j = 0; j < c['tags'].length; j++){
        tags += c['tags'][j]['label'] + ",";
      }
      //something feels wrong about this. i should make a fromMap() function 
      //c.add(Croak(id: croaks[i]['id'], content: croaks[i]['content'], timestamp: croaks[i]['timestamp'], tags: croaks[i]['tags'], score: croaks[i]['score']));
      
      print('saving: ' + croaks[i].toString());
      db.insert('croaks', {
        'id': c['id'],
        'p_id': c['p_id'],
        'created_at': c['created_at'],
        'content': c['content'],
        'score': c['score'],
        'tags': tags, 
        'x': c['x'],
        'y': c['y'],
        'type': c['type']
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      
    }
  });
  
}

Future<List> loadCroaks() async{
  Database db = await openDatabase(
    join(await getDatabasesPath(), 'fp.db'),
  );
  List<dynamic> dbres = await db.query('croaks', columns: ['*'], where: '1=1');
  List<dynamic> crks = List<dynamic>.from(dbres);
  return crks;
}

void saveTags(tags) async{

}

Future<List> loadTags() async{

}
