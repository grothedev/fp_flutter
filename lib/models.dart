import 'package:sqflite/sqflite.dart';
import 'dart:async';

class Croak{
  final int id;
  final String content;
  final String timestamp;
  final String tags;
  final int score;

  Croak(croak, {this.id, this.content, this.timestamp, this.tags, this.score});

  Map<String, dynamic> toMap(){
    return {
      'id': id,
      'score': score,
      'content': content,
      'tags': tags,
      'timestamp': timestamp
    };
  }
}