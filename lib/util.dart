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
import 'dart:math';

import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'api.dart' as api;
import 'db.dart' as db;
import 'consts.dart';

//NOTE: util might not be the best name
//these are helper functions to pass data to the api calls so that you don't have to worry about constructing the croak maps in event handlers

int lastUpdated;

//suggested tags for an area
Future<List> getTags(int n, LocationData location) async{
  if (location==null) return api.getTags(n, null, null);
  return api.getTags(n, location.latitude, location.longitude);
}

//should this function actually return the croaks or just say if it has written croaks to db?
Future<List> getCroaks(Query query, int lastUpdated, LocationData location) async{

  print('util getcroaks: ' + query.toString() + ', ' + query.radius.toString());
  
  //TODO fix sqlite
  if (true ||  lastUpdated == null || DateTime.now().millisecondsSinceEpoch - lastUpdated > CROAKS_GET_TIMEOUT){
    List crks =  await queryCroaks(location, query.tagsI, query.tagsIncludeAll, query.radius);
 
    print('util got croaks (tags=' + query.tagsI.toString() + ') :' + crks.toString());
    
    if (crks != null){
      db.saveCroaks(crks);
    }    
    return crks;
  } else {
    print('last got croaks ' + lastUpdated.toString() + '. loading croaks from sqlite');
    List dbres = await db.loadCroaks();
    print(dbres.toString());
    return List<dynamic>.from(dbres);
  }
}

Future<List> getReplies(int pid) async{
  List resJSON = await api.getCroaks(null, null, pid, null, false, null);
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

Future<bool> submitReply(int p_id, String content, List tags, anon) async{ //TODO should location be included?
  if (tags == null) print('no tags');   
  List<String> tagsStrArr = [];
  for (var t in tags){
    tagsStrArr.add(t['label']);
  }
  Croak c = new Croak(content: content, timestamp: new DateTime.now().toString() , score: 0, pid: p_id, tags: tagsStrArr, type: 0, lat: 0, lon: 0);
  return await postCroak(c.toMap(), null); //for now will not handle files for replies, but should in the future TODO
} 

Future<bool> submitCroak(String croak, List<String> tags, bool anon, double lat, double lon, File f) async{
  //print('util submit croak: ' + tags);
  Croak c = new Croak(content: croak, timestamp: new DateTime.now().toString() , score: 0, tags: tags, type: 0, pid: null, lat: lat, lon: lon, files: [f]);
  return await postCroak(c.toMap(), f);
}

Future<bool> postCroak(Map c, File f) async{
  var s = await api.postCroak(c, f);
  
  if (s == '0'){
      return true;
  }
  print(s);
  return false;
  
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


double distance(double latA, double lonA, double latB, double lonB){
  latA = latA * pi/180;
  latB = latB * pi/180;
  lonA = lonA * pi/180;
  lonB = lonB * pi/180;
  return acos( sin(latA)*sin(latB) + cos(latA)*cos(latB)*cos(lonA-lonB) ) * 6371;
}

//TODO make functions for varying croak type inputs