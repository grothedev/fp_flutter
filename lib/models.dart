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

import 'dart:convert';
import 'dart:io';
import 'package:location/location.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'consts.dart';

class AppState {

  //List<Map> feed;
  LocalCroaksStore localCroaks;
  bool gettingLocation;
  bool fetchingCroaks;
  int whenCroaksFetched;
  bool croaking;
  Query query; //specification of current croak-search query
  LocationData location;
  double lat, lon;
  bool needsUpdate = true; //this is used for some UI updates
  bool feedOutdated = true; //has the query been modified since the last time the croaks were fetched from server?
  bool updateReplies = true;
  int lastCroaksGet; //milliseconds since epoch since last time croaks were fetched
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


//TODO should this class be removed?. it is only used to construct a newly composed croak, which could be moved to LocalCroaksStore
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

  LocalCroaksStore(List<Map> croaks){
    if (croaks == null) return;
    croaks.forEach((c){
      if (!c.containsKey('listen')) c['listen'] = false;
      if (!c.containsKey('feed')) c['feed'] = false;
    });
  }

  //add a single croak or a list of croaks
  dynamic add(dynamic add, bool feed, bool listen){
    if (add is Map){
      add['feed'] = feed;
      add['listen'] = listen;
      croaks.add(add);
    } else if (add is List){
      add.forEach((c){
        c['feed'] = feed;
        c['listen'] = listen;
        croaks.add(c);
      });
    }
    return add;
  }

  List<Map> getFeed(SortMethod sm){
    List feed = croaks.where( (c) => c['feed'] ).toList();
    if (sm != null) sort(feed, sm); 
    return feed;

  }

  List<int> getListeningIDs(){
    return croaks.where( (c) => c['listen'] ).map( (c) => c['id'] ).toList();
  }

  //can pass in a list (for now will only be a list of croaks) to sort or leave null to use entire LocalCroaksStore croaks
  void sort(List l, SortMethod mthd){
    // sort methods: date, proximity, popularity 
    print(mthd.toString());
    if (l == null) l = croaks;
    switch(mthd){
      case SortMethod.date_asc:
        l.sort((a, b){
          return b['created_at'].compareTo(a['created_at']);
        });  
        break;
      case SortMethod.dist_asc:
        l.sort((a, b){
          return a['distance'].toInt() - b['distance'].toInt();
        });
        break;
      case SortMethod.pop_asc:
        l.sort((a, b){
          return a['replies'] - b['replies'];
        });
        break;
      case SortMethod.score_asc:
        l.sort((a, b){
          return a['score'] - b['score'];
        });
        break;
      case SortMethod.date_des:
        l.sort((a, b){
          return a['created_at'].compareTo(b['created_at']);
        });  
        break;
      case SortMethod.dist_des:
        l.sort((a, b){
          return b['distance'].toInt() - a['distance'].toInt();
        });
        break;
      case SortMethod.pop_des:
        l.sort((a, b){
          return b['replies'] - a['replies'];
        });
        break;
      case SortMethod.score_des:
        l.sort((a, b){
          return b['score'] - a['score'];
        });
        break;
    }
  }

  static LocalCroaksStore fromJSON(String str){
    if (str.length == 0) return new LocalCroaksStore(null);
    List<Map> croaks = List.from(jsonDecode(str));
    return new LocalCroaksStore(croaks);
  }

  String toJSON(){
    return jsonEncode(croaks);
  }
}