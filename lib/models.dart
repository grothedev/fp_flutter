import 'package:sqflite/sqflite.dart';
import 'dart:async';

class Croak{
  int id;
  final String content;
  final String timestamp;
  final String tags;
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