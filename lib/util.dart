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

//TODO might be a good to delegate all sharedpref functionality to util

int lastUpdated;
LocationData location;


Future<List> getSugTags(){
  //TODO probably obsolete now
}

//should this function actually return the croaks or just say if it has written croaks to db?
Future<List> getCroaks() async{

  List crks;

  if (location == null){
    await initLocation();
  }
  
  //TODO remove dbging true
  if (true || lastUpdated == null || DateTime.now().millisecondsSinceEpoch - lastUpdated > CROAKS_GET_TIMEOUT){
    return await queryCroaks(location, null); //TODO get taglist
  }



  SharedPreferences.getInstance().then((prefs){
      lastUpdated = prefs.getInt('last_croaks_get');

      if (true || lastUpdated == null || DateTime.now().millisecondsSinceEpoch - lastUpdated > CROAKS_GET_TIMEOUT){
        initLocation().then((l){
          if (l != null){
            prefs.setDouble('lat', l.longitude);
            prefs.setDouble('lon', l.latitude);
          } else {
            print('null loc');
          }
          print('util.getCroaks: l='+l.toString() + '; '); 
          queryCroaks(l, prefs.getStringList('tags')).then((r){
            db.saveCroaks(r);
            prefs.setInt('last_croaks_get', DateTime.now().millisecondsSinceEpoch);
            crks = r;
          });
        }).timeout(new Duration(seconds: 12), onTimeout: (){
          return queryCroaks(null, prefs.getStringList('tags'));
        });

      } else {
        print('loading croaks from sqlite');
        db.loadCroaks().then((crks){
          print('croaks loaded: ' + crks.toString());
          return crks.toList();
        });
      }
    });

    return crks;
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
    resJSON = await api.getCroaks(x, y, 0, tagList);
    resJSON.sort((a, b){
      return DateTime.parse(b['created_at']).millisecondsSinceEpoch - DateTime.parse(a['created_at']).millisecondsSinceEpoch;
    });
    return resJSON;
}

Future<List> getReplies(int p_id){
  return api.getCroaks(null, null, p_id, null);
}

Future<bool> submitReply(int p_id, String content, String tags, anon) async{ //TODO support user account posting 
  Croak c = new Croak(content: content, timestamp: new DateTime.now().toString() , score: 0, pid: p_id);
  return await postCroak(c.toMap());
}

Future<bool> submitCroak(String croak, String tags, bool anon, double lat, double lon) async{
  Croak c = new Croak(content: croak, timestamp: new DateTime.now().toString() , score: 0, tags: tags.split(' '), type: 0, pid: 0, lat: lat, lon: lon);
  return await postCroak(c.toMap());
}

Future<bool> postCroak(Map c) async{
  var s = await api.postCroak(c);
  
  if (s == '0'){
      return true;
  }
  return false;
  
}

Future<LocationData> initLocation() async{
    print('initing loc');
    if (location != null) return location;

    Location().serviceEnabled().then((s){
      if (!s) Location().requestService().then((r){
        if (!r) {
          print('service denied');
          return null;
        }
      });
    });
   
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
      return Location().getLocation();
      
    } on PlatformException catch (e){
      if (e.code == 'PERMISSION_DENIED'){
        print('permission denied');
      }
      print(e.code);
      return null;
    }
      
  }

//TODO make functions for varying croak type inputs