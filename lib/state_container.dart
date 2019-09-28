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

import 'package:background_fetch/background_fetch.dart';
import 'package:background_fetch/background_fetch.dart' as prefix0;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'util.dart' as util;

class StateContainer extends StatefulWidget{
  
  /*
    for future reference, different state design patterns: MobX, rxdart, BloC, flux vs redux, get_it, provider
  */

  final AppState state;
  final SharedPreferences prefs;
  Widget child;
  

  StateContainer({
    @required this.child,
    this.state,
    this.prefs
  });

  static StateContainerState of(BuildContext context){
    return (context.inheritFromWidgetOfExactType(InheritedStateContainer)
      as InheritedStateContainer).data;
  }

  @override
  State<StatefulWidget> createState() {
        return StateContainerState();
  }
  
}

class StateContainerState extends State<StateContainer>{

  AppState state;
  SharedPreferences prefs; //i think that all preference updating should be delegated to this class, because whenever a pref is updated state is also updated
  
  //apparently this method isn't executed
  @override
  void initState(){

    setupBGFetch();

    if (widget.state != null){
      print('state container widget already has appstate');
      state = widget.state;
      prefs = widget.prefs;
    } else {
      print('init state container widget appstate');
      state = AppState();
      restoreState();
      
    }
    initNotifications();
    super.initState();
  }

  
  void restoreState() async{ //from saved session preferences
    prefs = await SharedPreferences.getInstance();
    print('FROGPOND RESTORING SHARED PREFS');

    if (prefs.containsKey('ran_before')){
      state.lastCroaksGet = prefs.getInt('last_croaks_get');
      state.feedOutdated = prefs.getBool('feed_outdated');

      state.lat = prefs.getDouble('lat');
      state.lon = prefs.getDouble('lon');
      state.query.tagsIncludeAll = prefs.getBool('exclusive');
      if (state.query.tagsIncludeAll == null) state.query.tagsIncludeAll = false;
      //state.query.tags = prefs.getStringList('tags'); //tmp for dbging
      state.query.radius = prefs.getInt('radius');
      if (state.query.radius == null) state.query.radius = 15;
      //state.query.localTags = new LocalTagsStore(prefs.getStringList('tags')); //NOTE: currently cant save if the tag is being used. can only save list of strings
      state.query.localTags = LocalTagsStore.fromJSON(prefs.getString('local_tags'));
      state.localCroaks = LocalCroaksStore.fromJSON(prefs.getString('local_croaks'));

      //state.feed = jsonDecode(prefs.getString('feed_croaks'));
      state.notifyCheckInterval = prefs.getInt('notify_check_interval');
      
      state.needsUpdate = prefs.getBool('needs_update');
      state.feedOutdated = prefs.getBool('feed_outdated') || false;
    } else {
      prefs.setBool('ran_before', true); 
      prefs.setBool('feed_outdated', true);
      state.feedOutdated = true;    
      state.query.localTags = new LocalTagsStore(null); 
      prefs.setString('local_tags', '');
      state.localCroaks = new LocalCroaksStore(null);
      prefs.setString('local_croaks', '');
    }
    
    if (state.lat == null || state.lon == null){
      getLocation();
        //getSuggestedTags(); don't actually need to wait for location to be gotten because phase 1 is keeping global popular tags
    } else {
      print('restored lat lon from shared prefs');
      state.location = LocationData.fromMap({'latitude': state.lat, 'longitude': state.lon});
      print(state.location.latitude.toString());
    }

    if (state.needsUpdate == null) state.needsUpdate = true;
  
  }

  void setupBGFetch(){
    //so far this works for app onPause (home button), but not for onStop (back button)
    BackgroundFetch.configure(BackgroundFetchConfig(
      enableHeadless: true,
      minimumFetchInterval: 15,
      stopOnTerminate: false,
      
    ), util.checkNotifications);
    //), (){ print('callback check'); });

    // BackgroundFetch.registerHeadlessTask(util.checkNotifications);
  }

  @override
  Widget build(BuildContext context) {
    return InheritedStateContainer(
      data: this,
      child: widget.child,
    );
  }
  
  //actions for dealing with state data are here
  void addTag(String t, int mode){
    setState(() {
      state.query.localTags.add(t, true);
      state.query.localTags.set(t, mode); 
      state.feedOutdated = true;
    });
    prefs.setString('local_tags', state.query.localTags.toJSON());
    prefs.setBool('feed_outdated', true);
  }

  //doesn't actually remove the tag, but exludes it from query
  void removeTag(String t){
    setState((){
      state.query.localTags.get(t)['use'] = false;
      //state.query.tagsI.remove(t);
      state.feedOutdated = true;
    });
    prefs.setString('local_tags', state.query.localTags.toJSON());
    prefs.setBool('feed_outdated', true);
  }

  void removeLocalTags(){
    setState(() {
      state.query.localTags.empty();
      state.feedOutdated = true;
    });
    prefs.setString('local_tags', state.query.localTags.toJSON());
  }
  
  void useTag(String label, bool u){
    setState(() {
      state.query.localTags.use(label, u); 
      state.feedOutdated = true;
    });
    prefs.setString('local_tags', state.query.localTags.toJSON());
  }

  void toggleUseTag(String label){
    setState(() {
      state.query.localTags.toggleUse(label);
      state.feedOutdated = true;
    });
    prefs.setString('local_tags', state.query.localTags.toJSON());
    prefs.setBool('feed_outdated', true);
  }

  void tagsIncludeAll(bool a){
    setState(() {
      state.query.tagsIncludeAll = a;
      state.feedOutdated = true;
    });
    prefs.setString('local_tags', state.query.localTags.toJSON());
    prefs.setBool('feed_outdated', true);
  }

  void getSuggestedTags(){
    util.getTags(10, state.location).then((r){
      setState((){
        List<String> tagLbls = r.map((t){ return t['label'].toString(); }).toList();
        print('store gettin sugtags: ' + tagLbls.toString());
        if (state.query.localTags == null) state.query.localTags = new LocalTagsStore(tagLbls);
        else state.query.localTags.add(tagLbls, false);  
      });
      state.needsUpdate = true;
      prefs.setString('local_tags', state.query.localTags.toJSON());
    }); 
  }

  void setRadius(int r){
    print('store setting rad ' + r.toString());
    if (state.query.radius != r){
      setState((){
        state.query.radius = r;
        state.feedOutdated = true;
      });
      prefs.setBool('feed_outdated', true);
    }
  }

  //currently obsolete because only using km
  void setDistUnit(int u){
    setState(() {
      state.query.distUnit = u;
      state.feedOutdated = true;
    });
    prefs.setBool('feed_outdated', true);
  }

  void setSortMethod(int s){
    //TODO
  }

  void getLocation(){
    util.initLocation().then((l){
      setState(() {
        state.location = l;
        state.needsUpdate = true;
        state.lat = l.latitude;
        state.lon = l.longitude;
        
      });
      SharedPreferences.getInstance().then((p){
        p.setDouble('lat', l.latitude);
        p.setDouble('lon', l.longitude);
      });
    });
    
  }

  void needsUpdate(){ //this is just for croaks and location. i should rename it. 2019/8/24: i've started using it for tags as well. i should figure out exactly how this flag is being used because i don't remember, but it seems to make some ui updates work
    setState(() {
      state.needsUpdate = true;
    });
  }
  void needsNoUpdate(){
    setState((){
      state.needsUpdate = false;
    });
  }

  void setNotificationInterval(int ni){
    setState(() {
      state.notifyCheckInterval = ni;
    });
  }

  void toggleSubscribe(int id){
    setState(() {
      state.localCroaks.toggleSubscribe(id);  
    });
    prefs.setString('local_croaks', state.localCroaks.toJSON());
    print(state.localCroaks.get(id).toString());
  }

  void updateReplies(){
    setState((){
      state.updateReplies = true;
    });
  }
  void gotReplies(List r){
    setState(() {
      state.updateReplies = false;
    });
    state.localCroaks.add(r, false, false);
    prefs.setString('local_croaks', state.localCroaks.toJSON());
  }


  void gotFeed(List c){
    state.lastCroaksGet = DateTime.now().millisecondsSinceEpoch;
    prefs.setInt('last_croaks_get', state.lastCroaksGet);
    prefs.setBool('feed_outdated', false);
    //prefs.setString('feed_croaks', jsonEncode(state.feed));

    state.localCroaks.add(c, true, false);
    prefs.setString('local_croaks', state.localCroaks.toJSON());
  }

  void croaking(){
    setState(() {
      state.croaking = true;
    });
  }

  void croaked(Map c){
    setState(() {
      state.croaking = false;
    });
    if (c == null) return;
    state.localCroaks.add(c, false, true);
    prefs.setString('local_croaks', state.localCroaks.toJSON());
  }

  //writes all relevant state to sharedPrefs. called upon app close
  void saveState(){
    print('FROGPOND SAVING STATE: ');
    
    prefs.setDouble('lat', state.lat);
    prefs.setDouble('lon', state.lon);
    prefs.setInt('last_croaks_get', state.lastCroaksGet);
    prefs.setInt('radius', state.query.radius);
    prefs.setInt('last_croaks_get', state.lastCroaksGet);

    prefs.setBool('feed_outdated', false);
    //prefs.setString('feed_croaks', jsonEncode(state.feed));
    prefs.setString('local_tags', state.query.localTags.toJSON());
    prefs.setString('local_croaks', state.localCroaks.toJSON());
  }

  @protected
  @mustCallSuper
  @override
  void dispose(){
    super.dispose();
  }

  @protected
  @mustCallSuper
  @override
  void deactivate(){
    super.deactivate();
  }

  void initNotifications() async{
    state.notificationsPlugin = new FlutterLocalNotificationsPlugin();
    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    var initializationSettingsAndroid = new AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings( ); //onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    var initializationSettings = new InitializationSettings( initializationSettingsAndroid, initializationSettingsIOS);
    state.notificationsPlugin.initialize(initializationSettings, ); //onSelectNotification: onSelectNotification);
  
    //var scheduledNotificationDateTime = new DateTime.now().add(new Duration(seconds: 5));
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails('your other channel id',
        'your other channel name', 'your other channel description', priority: Priority.High);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    NotificationDetails platformChannelSpecifics = new NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    //await store.state.notificationsPlugin.schedule(0, 'someone has replied to you', '# frogs have croaked back since [time]', scheduledNotificationDateTime, platformChannelSpecifics);
    //store.state.notificationsPlugin.show(1, 'test title', 'test body', platformChannelSpecifics);

    //store.state.notificationsPlugin.periodicallyShow(1, 'test title', 'test body', RepeatInterval.EveryMinute, platformChannelSpecifics);
    
    //https://pub.dev/packages/flutter_local_notifications
  }

}

class InheritedStateContainer extends InheritedWidget{
  final StateContainerState data;

  InheritedStateContainer({
    Key key,
    @required this.data,
    @required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {    
    return true;
  }
}