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

import 'dart:io';
import 'package:location/location.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'consts.dart';
import 'util.dart' as util;

class AppState {

  List feed; //current croaks in the main feed
  bool gettingLocation;
  bool fetchingCroaks;
  int whenCroaksFetched;
  bool croaking;
  Query query; //specification of current croak-search query
  LocationData location;
  double lat, lon;
  bool needsUpdate = true;
  bool updateReplies = true;
  int lastCroaksGet;
  FlutterLocalNotificationsPlugin notificationsPlugin;
  int notifyCheckInterval; //minutes between checking for conditions which trigger notification
  
  AppState(){
    fetchingCroaks = false;
    croaking = false;
    //needsUpdate = true;
    query = Query();
  }

}

class Query{
  List<String> tagsI;
  List<String> tagsE;
  LocalTagsStore localTags;
  bool tagsIncludeAll; //get croaks which are associated with all (true) or some (false) of selected tags
  int radius;
  int distUnit;
  //TODO add keywords

  Query(){
    tagsI = List();
    tagsE = List();
    tagsIncludeAll = false;
    radius = 0;
    distUnit = KM;
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

  
  Croak({this.id, this.pid, this.content, this.timestamp, this.score, this.lat, this.lon, this.type, this.tags, this.files}){
    
    List<String> ts = []; //temp list to fix duplicates
    tags.forEach((t){ 
      if (!ts.contains(t)) ts.add(t);
    });
    this.tags = ts;
  }


  Map<String, dynamic> toMap(){
    return {
      'id': id.toString(),
      'p_id': pid != null ? pid.toString() : '',
      'user_id': uid != null ? uid.toString() : '',
      'x': lon.toString(),
      'y': lat.toString(),
      'score': score.toString(),
      'content': content,
      'tags': tags.join(','),
      'timestamp': timestamp,
      'type': type.toString(),
      'files': files.toString()
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

/*
a type of repository that handles the tags that are of concern to the user.
decided to do it this way because i wanted a few things to happen:
  - tags are saved and restored when the app is opened again
  - user can enter indivual tags of mode include or exclude and then they appear in the chip selector with the suggested tags
  - 

*/
class LocalTagsStore{
  List<dynamic> tags = [];
  //might keep two lists of tags: include and exclude, then present two filter chip scrollables

  LocalTagsStore(List<String> tags){
    if (tags == null) return;
    tags.forEach((t){
      add(t, false);
    });
  }

  void set(String label, int mode){
    get(label)['mode'] = mode;
  }

  //toggles whether or not to use this tag in query
  void use(String label){
    Map t = get(label);
    t['use'] = !t['use'];
  }

  Map<String, dynamic> get(String label){
    var tag = tags.firstWhere((t){ return t['label'] == label; });
    if (tag == null){
      print('tag doesnt exist');
      tag = add(label, false);
    }
    return tag;
  }

  List<String> getLabels(){
    List<String> res =  tags.map((t){ return t['label'].toString(); }).toList();
    print(res.toString());
    return res;
  }

  List<String> getActiveTagsLabels(){ //might as well combine filtering and mapping since that's the only use case so far
    return tags.where((t){ return t['use']; }).map((t){ return t['label'].toString(); }).toList();
  }

  dynamic add(dynamic label, bool use){
    if (label is String){
      if ( tags.where((t){ return t['label'].toLowerCase() == label.toLowerCase(); }).isNotEmpty ) return null;
      print('lts receiving string: ' + label);
      this.tags.add({
        'label': label,
        'mode': 0, //0=include, 1=exclude; using int because there might be more modes in future
        'use': use,
      });
      return this.tags.last;
    } else if (label is List<String>){
      print('lts receiving list: ' + label.toString());
      List added = [];
      label.forEach((l){
        added.add(add(l, use));
      });
      print('local tags store: ' + this.tags.toString());  
      return added;
    } else return null;
  }

  void empty(){
    tags.clear();
    tags = [];
  }
}