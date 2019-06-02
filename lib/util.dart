import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'api.dart' as api;
import 'db.dart' as db;

//NOTE: util might not be the best name
//these are helper functions to pass data to the api calls so that you don't have to worry about constructing the croak maps in event handlers

Future<List> getSugTags(){
  //TODO
}

//TODO deal with checking last update and getting user's location here instead of feedscreen class?
Future<List> getCroaks(loc, tagList){
    List resJSON;
    
    double x, y;
    if (loc != null){
      x = loc.longitude;
      y = loc.latitude;
    } else {
      x = y = null;
    }

    return api.getCroaks(x, y, 0, tagList);
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

//TODO make functions for varying croak type inputs