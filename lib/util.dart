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
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

Future<List> getCroaks(Query query, LocationData location) async{
    List<String> tags;
    if (query.localTags != null) tags = query.localTags.getActiveTagsLabels();
    print('querying api for croaks');
    List crks =  await queryCroaks(location, tags, query.tagsIncludeAll, query.radius).timeout(Duration(seconds: 16), onTimeout: (){
      return null;
    });
    return crks;
}

Future<List> getReplies(dynamic pid) async{
  List resJSON = await api.getCroaks(null, null, pid, null, false, null);
  //resJSON.forEach( (c) => c['listen'] = false );
  if (resJSON == null) return null; //network error
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
  return await postCroak(c.toMap(), null) != null; //for now will not handle files for replies, but should in the future 
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
  try {
    return jsonDecode(s);
  } catch (e) {
    return {'error': e.toString() + ':  ' + s};
  }
}

//returns that croak's current score
Future<int> vote(bool v, int c_id) async{
  Map<String, dynamic> req = {
    'v': v ? '1' : '0',
    'croak_id': c_id.toString()
  };
  String res = await api.postVote(req); 
  if (res != null) return int.parse(res);
  return null;
}

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

void reportCroak(int id){
  api.reportCroak(id);
}


//checks if there are responses to croaks this user has posted, if so send system notification
void checkNotifications() async{ 
  //store a collection of ids for which the user is concerned. by default, this is their own posts. sharedpref 'croaksListening'
  //need to keep track of which croaks have been seen too
  //print('BG_FETCH: util notifications check');

  SharedPreferences.getInstance().then((p) async {
    print(LocalCroaksStore.fromJSON(p.getString('local_croaks')).getListeningIDs().toString());
    LocalCroaksStore croaksStore = LocalCroaksStore.fromJSON(p.getString('local_croaks'));
    List notifyIDs = []; //a list of ids of croaks which have new replies
    
    List lids = croaksStore.getListeningIDs();
    String lidsStr = lids.join(',');

    lids.asMap().forEach((i, id) async { // reduce to one http request
      List replies = await getReplies(id);
      List localReplies = croaksStore.repliesOf(id);
      print('checking for new replies on croak ' + id.toString() + ': ' + replies.length.toString() + ', ' +  localReplies.length.toString() );
      print(replies.toString());
      print(localReplies.toString());
      print('');

      if (replies.length != localReplies.length){
        notifyIDs.add(id);          
      } else{ 
        //there are no new replies for this croak
        notifyIDs.add(-1*id);
      }
      if (i == lids.length-1){
        p.setString('notify_ids', jsonEncode(notifyIDs));
        print('ids of croaks which user will be notified of replies: ' + notifyIDs.toString()); 
        notify(notifyIDs);
      }
    });
  });
  BackgroundFetch.finish();
}

void notify(List ids) async{
  FlutterLocalNotificationsPlugin notificationsPlugin = new FlutterLocalNotificationsPlugin();
  // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  var initializationSettingsAndroid = new AndroidInitializationSettings('@mipmap/ic_launcher');
  var initializationSettingsIOS = new IOSInitializationSettings( ); //onDidReceiveLocalNotification: onDidReceiveLocalNotification);
  var initializationSettings = new InitializationSettings( initializationSettingsAndroid, initializationSettingsIOS);
  notificationsPlugin.initialize(initializationSettings, onSelectNotification: handleSelectNotification);

  //var scheduledNotificationDateTime = new DateTime.now().add(new Duration(seconds: 5));
  var androidPlatformChannelSpecifics = new AndroidNotificationDetails('your other channel id',
      'your other channel name', 'your other channel description', priority: Priority.High);
  var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
  NotificationDetails platformChannelSpecifics = new NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
  //await store.state.notificationsPlugin.schedule(0, 'someone has replied to you', '# frogs have croaked back since [time]', scheduledNotificationDateTime, platformChannelSpecifics);
  notificationsPlugin.show(1, 'You have new replies!', ids.toString(), platformChannelSpecifics, payload: ids.toString());

  //store.state.notificationsPlugin.periodicallyShow(1, 'test title', 'test body', RepeatInterval.EveryMinute, platformChannelSpecifics);
  
  //https://pub.dev/packages/flutter_local_notifications
}

Future handleSelectNotification(String idsStr){ //TODO need to get context of app here
  List ids = idsStr.split(', ');
  print('handling notification selection');
  //Navigator.push();
}

double distance(double latA, double lonA, double latB, double lonB){
  latA = latA * pi/180;
  latB = latB * pi/180;
  lonA = lonA * pi/180;
  lonB = lonB * pi/180;
  return acos( sin(latA)*sin(latB) + cos(latA)*cos(latB)*cos(lonA-lonB) ) * 6371;
}

//my own jsonEncode made when i had to deal with a Map<int, int> (convert it to Map<String, int>)
String jsonEncodeM(Map m){
  return jsonEncode( m.map( (i, t) => MapEntry<String, int>(i.toString(), t) ) );
}

//log an error msg to a text file
void errLog(String msg) async {
  File f = await localFile('error.log');
  f.writeAsString(DateTime.now().toIso8601String() + ': ' + msg);
  print('ERRlog: ' + msg);
}

void fileTest() async{
  File f = await localFile('test.txt');
  print(f.path.toString());
  print(f.toString());
  f.writeAsString('file test: ' + DateTime.now().toLocal().toString());
}

Future<String> get localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> localFile(String fname) async {
  final path = await localPath;
  return File('$path/' + fname);
}

