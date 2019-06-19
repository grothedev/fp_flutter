import 'dart:io';
import 'package:location/location.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';


class AppState {

  String test = 'inherit widget test';
  List feed; //current croaks in the main feed
  bool gettingLocation;
  bool fetchingCroaks;
  int whenCroaksFetched;
  Query query; //specification of current croak-search query
  LocationData location;
  bool needsUpdate;

  AppState(){
    fetchingCroaks = false;
    needsUpdate = true;
    query = Query();
  }

}

class Query{
  List<String> tags;
  bool exclusive; //get croaks with all or some tags
  //TODO add keywords

  Query(){
    tags = List();
  }
}

class Croak{
  int id;
  int pid; //parent
  int uid; //user (author)
  double lat, lon;
  final String content;
  final String timestamp;
  List<String> tags; //in the future, tags might have to be more aligned with the data structure on the server
  List<File> files;
  final int score;
  final int type;

  
  Croak({this.id, this.pid, this.content, this.timestamp, this.score, this.lat, this.lon, this.type, this.tags, this.files});


  Map<String, dynamic> toMap(){
    return {
      'id': id.toString(),
      'p_id': pid.toString(),
      'score': score.toString(),
      'content': content,
      'tags': tags.join(','),
      'timestamp': timestamp,
      'type': type.toString(),
    };
  }
  
  String toJSON(){
    
  }
}

class Tag{
  int id;
  String label;
  List<Croak> croaks;

  Tag({this.id, this.label, this.croaks});

  Map<String, dynamic> toMap(){
    return {
      'id': id,
      'label': label,
      'croaks': croaks
    };
  }

  String toString(){
    return label;
  }
}