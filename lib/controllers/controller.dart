import 'dart:convert';

import 'package:FrogPond/models/appstate.dart';
import 'package:FrogPond/models/croakstore.dart';
import 'package:FrogPond/models/tagstore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

/**
 * this is a base controller for frogpond 
 */
class Controller extends GetxController {
  var state;
  SharedPreferences prefs;
  Future<AppState> stateFuture;

  Controller(){
    SharedPreferences.getInstance().then((p)=>this.prefs=p);
    state = AppState().obs;
  }

  //populate app state based on saved preferences or default values if this is first run
  Future<AppState> restoreState() async {
    if (prefs.containsKey('ran_before')){
      state.lastCroaksGet = Map<String, int>.from(jsonDecode( prefs.getString('last_croaks_get') ));
      state.feedOutdated = prefs.getBool('feed_outdated');
      state.localCroaks = LocalCroaksStore.fromJSON(prefs.getString('local_croaks'));

      state.lat = prefs.getDouble('lat');
      state.lon = prefs.getDouble('lon');
      state.query.tagsIncludeAll = prefs.getBool('exclusive');
      if (state.query.tagsIncludeAll == null) state.query.tagsIncludeAll = false;
      state.query.radius = prefs.getInt('radius');
      if (state.query.radius == null) state.query.radius = 15;
      state.query.localTags = LocalTagsStore.fromJSON(prefs.getString('local_tags'));
      state.hasUnread = prefs.containsKey('has_unread') ? prefs.getBool('has_unread') : false;
      if (!prefs.containsKey('notify_check_interval')) prefs.setInt('notify_check_interval', 15);
      state.notifyCheckInterval = prefs.getInt('notify_check_interval');
      state.lefthand = prefs.getBool('left_hand') == null ? false : prefs.get('left_hand');
    } else {
      prefs.setBool('ran_before', true);
      //app state defaults have been set by AppState()
      saveStateToPrefs();
    }
    
    if (state.lat == null || state.lon == null){
      getLocation();
      //getSuggestedTags(); don't actually need to wait for location to be gotten because phase 1 is keeping global popular tags
    } else {
      state.location = LocationData.fromMap({'latitude': state.lat, 'longitude': state.lon});
      print(state.location.latitude.toString());
    }

    state.loading = false;
  }

  //writes all relevant app state to sharedPrefs.
  void saveStateToPrefs(){
    print('FROGPOND SAVING STATE: ');
    
    prefs.setDouble('lat', state.lat);
    prefs.setDouble('lon', state.lon);
    prefs.setString('last_croaks_get', jsonEncode(state.lastCroaksGet) );
    prefs.setInt('radius', state.query.radius);
    prefs.setBool('exclusive', state.query.tagsIncludeAll);
    prefs.setInt('dist_unit', state.query.distUnit);
    prefs.setBool('feed_outdated', state.feedOutdated);
    prefs.setString('local_tags', state.query.localTags.toJSON());
    prefs.setString('local_croaks', state.localCroaks.toJSON());
    prefs.setInt('notify_check_interval', state.notifyCheckInterval);
    prefs.setBool('has_unread', state.hasUnread);
    prefs.setBool('left_hand', state.lefthand);
  }

  //get the user's location and update its value in the app state
  void getLocation(){
    initLocation().then((l){
      state.location = l;
      state.lat = l.latitude;
      state.lon = l.longitude;
      
      prefs.setDouble('lat', l.latitude);
      prefs.setDouble('lon', l.longitude);
    });
  }

  Future<LocationData> initLocation() async{
    bool locServiceEnabled = await Location().serviceEnabled();
    if (!locServiceEnabled) {
      bool locServiceAllowed = await Location().requestService();
      if (!locServiceAllowed) {
        print('location service denied');
        return null;
      }
    }
   
    Location().hasPermission().then((permStatus){
      if (permStatus == PermissionStatus.denied) {
        Location().requestPermission().then((permStatus2){ //retry to ask for permission again
          if (permStatus == PermissionStatus.denied || permStatus == PermissionStatus.deniedForever) {
            print('permission denied');
            return null;
          }
        });
      } else if (permStatus == PermissionStatus.deniedForever){
        print('permission denied forever');
        return null;
      }
    });

    try{
      return await Location().getLocation();
    } on PlatformException catch (e){
      print(e.code);
      return null;
    }
      
  }

  void setRadius(r){
    if (state.query.radius != r){
      state.query.radius = r;
      state.feedOutdated = true;

      prefs.setBool('feed_outdated', true);
      prefs.setInt('radius', r);                            
    }
  }

  void setNotificationInterval(int ni){
    state.notifyCheckInterval = ni;
    prefs.setInt('notify_check_interval', ni);                       
  }
}

