import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'dart:async';

class Croak{
  int id;
  int pid; //parent
  int uid; //user (author)
  int lat, lon;
  final String content;
  final String timestamp;
  final List<String> tags; //in the future, tags might have to be more aligned with the data structure on the server
  final List<File> files = null;
  final int score;
  final int type = 0;

  
  Croak({this.id, this.content, this.timestamp, this.tags, this.score});

  Map<String, dynamic> toMap(){
    return {
      'id': id.toString(),
      'score': score.toString(),
      'content': content,
      'tags': tags,
      'timestamp': timestamp,
      'type': type.toString()
    };
  }

  String toJSON(){
    
  }
}