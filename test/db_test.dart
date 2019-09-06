/*
void initDB()
  should create a file 'fp.db' in the databasesPath directory if it doesn't exist, and set database instance variable equal to the database opened on that file
  database should have the proper columns
    croaks:
      id INTEGER PRIMARY KEY
      p_id INTEGER
      created_at TEXT
      content TEXT
      score INTEGER
      tags TEXT  //each tag separated by ','
      type INTEGER
      x REAL
      y REAL
      listening INTEGER  //bool is user listening for comments for device notification?

void saveCroaks(croaks)
  should insert each croak in the given list into local db, replacing ones with same id, 

Future<List> loadCroaks()
  should return a list of all records of croaks table from the database

*/

import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:test/test.dart';
import '../lib/db.dart' as db;

void main(){
  //initDB()
  test('fp.db should exists and contain the proper table', () async {
    db.initDB();
    File dbfile = File(getDatabasesPath().toString() + '/fp.db');
    expect(dbfile.exists(), true);
    List rows = await db.database.query('croaks');
    Map c = rows.elementAt(0);
    print(c.keys);
    expect(c.containsKey('content'), true);
  });

  //saveCroaks(croaks)
  test('db should have the new croaks added', (){
    Map c1 = {}; //new croak
    Map c2 = {}; //dupe with updated listening
    Map c3 = {}; //dupe

    

  });
}