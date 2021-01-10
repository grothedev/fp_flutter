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
  AppState st;
  SharedPreferences prefs;
  Future<SharedPreferences> prefsFuture;
  Future<AppState> stateFuture;

  Controller(){
    //prefsFuture = SharedPreferences.getInstance().then((p)=>this.prefs=p);
    state = AppState().obs;
    st = state(); //Rx to Object
  }

  //populate app state based on saved preferences or default values if this is first run
  Future<AppState> restoreState() async {
    //Future.wait([prefsFuture]);
    prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('ran_before')){
      st.lastCroaksGet = Map<String, int>.from(jsonDecode( prefs.getString('last_croaks_get') ));
      st.feedOutdated = prefs.getBool('feed_outdated');
      st.localCroaks = LocalCroaksStore.fromJSON(prefs.getString('local_croaks'));

      st.lat = prefs.getDouble('lat');
      st.lon = prefs.getDouble('lon');
      st.query.tagsIncludeAll = prefs.getBool('exclusive');
      if (st.query.tagsIncludeAll == null) st.query.tagsIncludeAll = false;
      st.query.radius = prefs.getInt('radius');
      if (st.query.radius == null) st.query.radius = 15;
      st.query.localTags = LocalTagsStore.fromJSON(prefs.getString('local_tags'));
      st.hasUnread = prefs.containsKey('has_unread') ? prefs.getBool('has_unread') : false;
      if (!prefs.containsKey('notify_check_interval')) prefs.setInt('notify_check_interval', 15);
      st.notifyCheckInterval = prefs.getInt('notify_check_interval');
      st.lefthand = prefs.getBool('left_hand') == null ? false : prefs.get('left_hand');
    } else {
      prefs.setBool('ran_before', true);
      //app state defaults have been set by AppState()
      saveStateToPrefs();
    }
    
    if (st.lat == null || st.lon == null){
      getLocation();
      //getSuggestedTags(); don't actually need to wait for location to be gotten because phase 1 is keeping global popular tags
    } else {
      st.location = LocationData.fromMap({'latitude': st.lat, 'longitude': st.lon});
      print(st.location.latitude.toString());
    }

    st.loading = false;
    return state();
  }

  //writes all relevant app state to sharedPrefs.
  void saveStateToPrefs(){
    print('FROGPOND SAVING STATE: ');
    
    prefs.setDouble('lat', st.lat);
    prefs.setDouble('lon', st.lon);
    prefs.setString('last_croaks_get', jsonEncode(st.lastCroaksGet) );
    prefs.setInt('radius', st.query.radius);
    prefs.setBool('exclusive', st.query.tagsIncludeAll);
    prefs.setInt('dist_unit', st.query.distUnit);
    prefs.setBool('feed_outdated', st.feedOutdated);
    prefs.setString('local_tags', st.query.localTags.toJSON());
    prefs.setString('local_croaks', st.localCroaks.toJSON());
    prefs.setInt('notify_check_interval', st.notifyCheckInterval);
    prefs.setBool('has_unread', st.hasUnread);
    prefs.setBool('left_hand', st.lefthand);
  }

  //get the user's location and update its value in the app state
  void getLocation(){
    initLocation().then((l){
      st.location = l;
      st.lat = l.latitude;
      st.lon = l.longitude;
      
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
    if (st.query.radius != r){
      st.query.radius = r;
      st.feedOutdated = true;

      prefs.setBool('feed_outdated', true);
      prefs.setInt('radius', r);                            
    }
  }

  void setNotificationInterval(int ni){
    st.notifyCheckInterval = ni;
    prefs.setInt('notify_check_interval', ni);                       
  }
}

