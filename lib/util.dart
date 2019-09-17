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
import 'dart:math';

import 'package:background_fetch/background_fetch.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'api.dart' as api;
import 'consts.dart';

//NOTE: util might not be the best name
//these are helper functions to pass data to the api calls so that you don't have to worry about constructing the croak maps in event handlers

int lastUpdated;

//suggested tags for an area
Future<List> getTags(int n, LocationData location) async{
  if (location==null) return api.getTags(n, null, null);
  print('UTIL GETTING TAGS');
  return api.getTags(n, location.latitude, location.longitude);
}

Future<List> getCroaks(Query query, int lastUpdated, LocationData location) async{

  if (lastUpdated == null || DateTime.now().millisecondsSinceEpoch - lastUpdated > CROAKS_GET_TIMEOUT){

    List<String> tags;
    if (query.localTags != null) tags = query.localTags.getActiveTagsLabels();
    List crks =  await queryCroaks(location, tags, query.tagsIncludeAll, query.radius);
    
    crks.forEach((c) => c['listen'] = false );
    
    return crks;
  } else {
    print('last got croaks ' + lastUpdated.toString() + '. loading croaks from shared prefs');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String croaksStr = prefs.getString('local_croaks');
    List<dynamic> cs = LocalCroaksStore.fromJSON(croaksStr).getFeed().toList(); //i think there is some redundance going on here
    return cs;
  }
}

Future<List> getReplies(int pid) async{
  List resJSON = await api.getCroaks(null, null, pid, null, false, null);
  resJSON.forEach( (c) => c['listen'] = false );
  resJSON.sort((a, b){
    return DateTime.parse(b['created_at']).millisecondsSinceEpoch - DateTime.parse(a['created_at']).millisecondsSinceEpoch;
  });
  return resJSON;
}

Future<List> queryCroaks(loc, tagList, qa, radius) async{
    List resJSON;
    
    double x, y;
    if (loc != null){
      x = loc.longitude;
      y = loc.latitude;
    } else {
      x = y = null;
    }
    resJSON = await api.getCroaks(x, y, 0, tagList, qa, radius);
    if (resJSON != null){
      resJSON.sort((a, b){
        return DateTime.parse(b['created_at']).millisecondsSinceEpoch - DateTime.parse(a['created_at']).millisecondsSinceEpoch;
      });
    }
    return resJSON;
}

Future<bool> submitReply(int p_id, String content, List tags, anon, LocationData loc) async{
  if (tags == null) print('no tags');   
  List<String> tagsStrArr = [];
  for (var t in tags){
    tagsStrArr.add(t['label']);
  }
  Croak c = new Croak(content: content, timestamp: new DateTime.now().toString() , score: 0, pid: p_id, tags: tagsStrArr, type: 0, lat: loc.latitude, lon: loc.longitude);
  return await postCroak(c.toMap(), null) != null; //for now will not handle files for replies, but should in the future TODO
} 

//return subbmited croak, or null on failure. saves croak to shared prefs
Future<Map> submitCroak(String croak, List<String> tags, bool anon, double lat, double lon, File f) async{
  Croak c = new Croak(content: croak, timestamp: new DateTime.now().toString() , score: 0, tags: tags, type: 0, pid: null, lat: lat, lon: lon, files: [f]);
  return await postCroak(c.toMap(), f);
}

//return submitted croak, or null upon failure
Future<Map> postCroak(Map c, File f) async{
  String s = await api.postCroak(c, f);
  if (s == '-1') return null;
  return jsonDecode(s);
}

//returns that croak's current score
Future<int> vote(bool v, int c_id) async{
  Map<String, dynamic> req = {
    'v': v ? '1' : '0',
    'croak_id': c_id.toString()
  };
  String res = await api.postVote(req); 
  return int.parse(res);
}

//TODO rename to getLocation ?
Future<LocationData> initLocation() async{
    print('initing loc');

    bool s = await Location().serviceEnabled();
    if (!s) {
      bool r = await Location().requestService();
      if (!r) {
        print('service denied');
        return null;
      }
    }
    
   
    Location().hasPermission().then((p){
      if (!p) Location().requestPermission().then((r){
        if (!r) {
          print('permission denied');
          return null;
        }
      });
    });

    try{
      print ('getting loc');
      return await Location().getLocation();
    } on PlatformException catch (e){
      if (e.code == 'PERMISSION_DENIED'){
        print('permission denied');
      }
      print(e.code);
      return null;
    }
      
  }


//checks if there are responses to croaks this user has posted, if so send system notification
void checkNotifications() async{ //TODO design how this is done: 
  //store a collection of ids for which the user is concerned. by default, this is their own posts. sharedpref 'croaksListening'
  //need to keep track of which croaks have been seen too
  //print('BG_FETCH: util notifications check');

  fileTest();

  SharedPreferences.getInstance().then((p){
    List croaks = jsonDecode(p.getString('local_croaks')).where( (c) => c['listen'] );
    croaks.forEach((c){
      getReplies(c['id']).then((res){
        //need to check if there are any new comments that don't exist in stored comments
        //or maybe 'listen' flag could be an int telling the last time the croakdetail screen was looked at, then seeing if any of the comments were posted after that
      });
    });
    
  });

  BackgroundFetch.finish();
}

double distance(double latA, double lonA, double latB, double lonB){
  latA = latA * pi/180;
  latB = latB * pi/180;
  lonA = lonA * pi/180;
  lonB = lonB * pi/180;
  return acos( sin(latA)*sin(latB) + cos(latA)*cos(latB)*cos(lonA-lonB) ) * 6371;
}

void fileTest() async{
  File f = await localFile;
  print(f.path.toString());
  print(f.toString());
  f.writeAsString('file test: ' + DateTime.now().toLocal().toString());
}

Future<String> get localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> get localFile async {
  final path = await localPath;
  return File('$path/test.txt');
}
