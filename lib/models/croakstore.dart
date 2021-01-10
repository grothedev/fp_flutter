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

import 'package:FrogPond/models/query.dart';
import 'package:intl/intl.dart';


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
      if (add['p_id'] == null) add['p_id'] = 0;
      add['vis'] = add['p_id'] == 0; //replies not visible by default
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
        if (c['p_id'] == null) c['p_id'] = 0;
        c['vis'] = c['p_id'] == 0; //replies not visible by default
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

  /**
   * returns the croaks that satisfy given query. used to modify the stored croaks list, but now just return a new sublist
   */
  List ofQuery(Query q){
    List res = [];
    croaks.forEach((c){
      bool hasTags; //satisfies the tag requirement
      bool inRange=false;
      if (c['p_id'] != null && c['p_id'] > 0){ //comments are never results of a query
        c['vis'] = false;
      } else {
        List cTags = c['tags'] == null ? [] : c['tags'].map((t) => t['label']).toList();
        if (q.tagsIncludeAll){
          //check that all of the tags of this croak are contained within localTags active tags
          hasTags=true;
          for (String at in q.localTags.getActiveTagsLabels()){
            if (!cTags.contains(at)){
              hasTags = false;
              break;
            }
          }
        } else {
          //check that at least one tag of this croak is contained within localTags active tags
          hasTags=false;
          for (String at in q.localTags.getActiveTagsLabels()){
            if (cTags.contains(at)){
              hasTags = true;
              break;
            }
          }
        }
        if (q.radius != null && q.radius > 0){
          if (c['distance'] != null && c['distance'] < q.radius) inRange = true;
          //TODO if c['distance']==null calculate dist here (this means the croak was downloaded with any-radius query)
        }
        if (hasTags && inRange) res.add(c);
      }
    });
    return res;
  }

  //make all croaks invisible to the feed
  void hideAll(){
    croaks.forEach((c) => c['vis'] = false);
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