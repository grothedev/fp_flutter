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
along with Frog Pond.  If not, see <https://www.gnu.org/licenses/>.
*/

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'consts.dart';

class AppState {

  //List<Map> feed;
  LocalCroaksStore localCroaks;
  bool hasUnread; //if there are croaks to which the user is subscribed and that have new replies
  bool gettingLocation;
  bool fetchingCroaks;
  int whenCroaksFetched;
  bool croaking;
  Query query; //specification of current croak-search query
  LocationData location;
  double lat, lon;
  bool needsUpdate = true; //this is used for some UI updates
  bool feedOutdated = true; //has the query been modified since the last time the croaks were fetched from server?
  bool newReplies = false;
  Map<String, int> lastCroaksGet; //milliseconds since epoch since last time croaks were fetched for each p_id (0=root). String -> int to keep w/ JSON format; would be ideal to have int -> int
  FlutterLocalNotificationsPlugin notificationsPlugin;
  int notifyCheckInterval = 0; //minutes between checking for conditions which trigger notification
  bool lefthand = false; //left handed user

  AppState(){
    lastCroaksGet = Map<String, int>();
    fetchingCroaks = false;
    croaking = false;
    hasUnread = false;
    //needsUpdate = true;
    query = Query();
  }
  
}

class Query{
  LocalTagsStore localTags;
  bool tagsIncludeAll; //get croaks which are associated with all (true) or some (false) of selected tags
  int radius;
  int distUnit;
  //TODO add keywords

  Query(){
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

  LocalTagsStore(List<dynamic> tags){
    if (tags == null || tags.length == 0) return;
    if (tags[0] is String){
      tags.forEach((t){
        add(t, false);
      });
    } else if (tags[0] is Map){
      if (tags[0].containsKey('label') && tags[0].containsKey('mode') && tags[0].containsKey('use')){
        this.tags = List.from(tags);
      }
    } 
  }

  void set(String label, int mode){
    get(label)['mode'] = mode;
  }

  //toggles whether or not to use this tag in query
  void toggleUse(String label){
    Map t = get(label);
    t['use'] = !t['use'];
  }

  void use(String label, bool u){
    Map t = get(label);
    t['use'] = u;
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

  //returns a new LTS from the string representation stored in shared prefs
  static LocalTagsStore fromJSON(String str){
    if (str.length == 0) return new LocalTagsStore(null);
    List tags = List.from(jsonDecode(str));
    return new LocalTagsStore(tags);
  }

  //returns string of json representation of this LocalTagsStore
  String toJSON(){
    return jsonEncode(tags);
  }


  String toString(){
    return tags.toString();
  }
}

/*
  a type of repository to handle croaks that have been retreived as main feed, comments, or submitted by the user
  similar to LocalTagsStore
  main reason for implementation is to keep track of which croaks are part of the feed and which are subscribed to

  NOTE: currently, the extra client-concerning flags are added to croak map right alongside existing structure. this should be ok
*/
class LocalCroaksStore{
  List<Map> croaks = [];

  LocalCroaksStore(List croaks){
    if (croaks == null) return;
    croaks.forEach((c){
      if (!c.containsKey('listen')) c['listen'] = false;
      if (!c.containsKey('feed')) c['feed'] = false;
      c['has_unread'] = false;
      this.croaks.add(c);
    });
  }

  //add a single croak or a list of croaks
  dynamic add(dynamic add, bool feed, bool listen){
    if (add is Map){
      List d = croaks.where((d)=>d['id']==add['id']).toList();
      if ( d.isNotEmpty ){
        d[0] = add;
        return add;
      }
      add['feed'] = feed; //is this croak in the feed?
      add['listen'] = listen; //is the user currently subscribed to this croak? (will receive notifications if it gets new replies)
      add['has_unread'] = false; //are there new replies to this croak which the user has not yet seen?
      add['vis'] = add['p_id'] != null && add['p_id'] > 0 ? false : true; //replies not visible by default
      if (add['replies'] == null) add['replies'] = 0;
      DateTime dt = DateFormat('yyyy-MM-d HH:mm').parse(add['created_at']).toLocal();
      add['timestampStr'] = dt.year.toString() + '/' + dt.month.toString() + '/' + dt.day.toString() + ' - ' + dt.hour.toString() + ':' + dt.minute.toString();
      croaks.add(add);
    } else if (add is List){
      add.forEach((c){
        List d = croaks.where((d)=>d['id']==c['id']).toList();
        if ( d.isNotEmpty ){
          d[0] = c;
          return;
        }
        c['feed'] = feed;
        c['listen'] = listen;
        c['has_unread'] = false;
        c['vis'] = c['p_id'] != null && c['p_id'] > 0 ? false : true; //replies not visible by default
        if (c['replies'] == null) c['replies'] = 0;
        DateTime dt = DateFormat('yyyy-MM-d HH:mm').parse(c['created_at']).toLocal();
        c['timestampStr'] = dt.year.toString() + '/' + dt.month.toString() + '/' + dt.day.toString() + ' - ' + dt.hour.toString() + ':' + dt.minute.toString();
        croaks.add(c);
      });
    }
    return add;
  }

  Map get(int id){
    if (croaks == null || croaks.length == 0) return null;
    List cs = croaks.where( (c) => c['id'] == id).toList();
    return cs.isNotEmpty ? cs[0] : null;
  }

  List<Map> getFeed(){
    return croaks.where( (c) => c['feed'] ).toList();
  }

  List getListeningIDs(){
    return croaks.where( (c) => c['listen'] || c['listen'] == 'true' ).map( (c) => c['id'] ).toList();
  }

  List getListening(){
    return croaks.where( (c) => c['listen'] || c['listen'] == 'true' ).toList();
  }

  List getHasUnread(){ //croaks which have new replies that the user hasn't yet seen
    return croaks.where( (c) => c['has_unread']==true ).toList();
  }

  //returns the croaks that satisfy given query
  List ofQuery(Query q){
    croaks.forEach((c){
      if (c['p_id'] != null && c['p_id'] > 0){ //comments are never results of a query
        c['vis'] = false;
      } else {
        List cTags = c['tags'] == null ? [] : c['tags'].map((t) => t['label']).toList();
        if (q.tagsIncludeAll){
          //check that all of the tags of this croak are contained within localTags active tags
          c['vis'] = true;
          cTags.forEach((t){
            if (!q.localTags.getActiveTagsLabels().contains(t)){
              c['vis'] = false;
            }
          });
        } else {
          //check that at least one tag of this croak is contained within localTags active tags
          cTags.forEach((t){
            if (q.localTags.getActiveTagsLabels().contains(t)){
              c['vis'] = true;
            }
          });
        }
      }
    });
    
    return croaks;
  }

  bool satisfiesQuery(int id, Query q){
    return ofQuery(q).map((c)=>c['id']).contains(id);
  }

  List repliesOf(pid){
    return croaks.where((r)=> (r['p_id'] == pid)).toList();
  }

  void toggleSubscribe(int id) => get(id)['listen'] = !get(id)['listen'];

  void sub(int id) => get(id)['listen'] = true;

  void unsub(int id) => get(id)['listen'] = false;

  //declares that this croak has comments which the user hasn't seen
  void setUnread(int id) => get(id)['has_unread'] = true;

  bool hasUnread(int id) => get(id)['has_unread']; 

  List getUnread() => croaks.where((c) => c['has_unread']).toList();

  bool isEmpty() => croaks.isEmpty;

  static LocalCroaksStore fromJSON(String str){
    if (str == null || str.length == 0) return new LocalCroaksStore(null);
    List croaks = jsonDecode(str).toList();
    return new LocalCroaksStore(croaks);
  }

  String toJSON(){
    return jsonEncode(croaks);
  }
}