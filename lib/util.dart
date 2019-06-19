import 'dart:io';

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
LocationData location;
SharedPreferences prefs;

//suggested tags for an area
Future<List> getTags(int n) async{
  if (location == null) {
    initLocation().timeout(new Duration(seconds: 12)).then((loc){
      location = loc;
      return api.getTags(n, location.latitude, location.longitude);
    });
  } 
  return api.getTags(n, null, null);
  
  
}

//should this function actually return the croaks or just say if it has written croaks to db?
Future<List> getCroaks(Query query) async{
  
  List crks;

  if (prefs == null){
    prefs = await SharedPreferences.getInstance();
  }
  
  if (location == null){
    await initLocation().timeout(new Duration(seconds: 12));
  }
  

  lastUpdated = prefs.getInt('last_croaks_get');

  if (lastUpdated == null || DateTime.now().millisecondsSinceEpoch - lastUpdated > CROAKS_GET_TIMEOUT){
    List crks =  await queryCroaks(location, prefs.getStringList('tags')); //TODO get taglist. has this been done already?
    print('util get croaks (tags=' + prefs.getStringList('tags').toString() + ') :' + crks.toString());
    return crks;
  } else {
    print('loading croaks from sqlite');
    db.loadCroaks().then((crks){
      print('croaks loaded: ' + crks.toString());
      return crks.toList();
    });
  }
  //return crks;
}

Future<List> getReplies(int pid) async{
  List resJSON = await api.getCroaks(null, null, pid, null, null);
  resJSON.sort((a, b){
    return DateTime.parse(b['created_at']).millisecondsSinceEpoch - DateTime.parse(a['created_at']).millisecondsSinceEpoch;
  });
  return resJSON;
}

Future<List> queryCroaks(loc, tagList) async{
    List resJSON;
    
    double x, y;
    if (loc != null){
      x = loc.longitude;
      y = loc.latitude;
    } else {
      x = y = null;
    }
    print('util.queryCroaks');
    bool qa; //query all 
    if (prefs.getBool('query_all') == null) {
      qa = false;
      print('query all pref null, which is not supposed to be');
    }
    resJSON = await api.getCroaks(x, y, 0, tagList, qa);
    resJSON.sort((a, b){
      return DateTime.parse(b['created_at']).millisecondsSinceEpoch - DateTime.parse(a['created_at']).millisecondsSinceEpoch;
    });
    return resJSON;
}

Future<bool> submitReply(int p_id, String content, List tags, anon) async{ //TODO should location be included?
  List<String> tagsStrArr = [];
  for (var t in tags){
    tagsStrArr.add(t['label']);
  }
  Croak c = new Croak(content: content, timestamp: new DateTime.now().toString() , score: 0, pid: p_id, tags: tagsStrArr, type: 0);
  return await postCroak(c.toMap(), null); //for now will not handle files for replies, but should in the future TODO
}

Future<bool> submitCroak(String croak, String tags, bool anon, double lat, double lon, File f) async{
  Croak c = new Croak(content: croak, timestamp: new DateTime.now().toString() , score: 0, tags: tags.split(' '), type: 0, pid: null, lat: lat, lon: lon, files: [f]);
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

Future<LocationData> initLocation() async{
    print('initing loc');
    if (location != null) return location;

    if (prefs == null) prefs = await SharedPreferences.getInstance();

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
      LocationData l = await Location().getLocation();
      if (l != null){
        prefs.setDouble('lat', l.longitude);
        prefs.setDouble('lon', l.latitude);
      } else {
        print('null loc');
      }
      return l;

    } on PlatformException catch (e){
      if (e.code == 'PERMISSION_DENIED'){
        print('permission denied');
      }
      print(e.code);
      return null;
    }
      
  }

//TODO make functions for varying croak type inputs