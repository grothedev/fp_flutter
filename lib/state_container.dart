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

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:FrogPond/models/appstate.dart';
import 'package:FrogPond/models/croakstore.dart';
import 'package:FrogPond/models/tagstore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'consts.dart';
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


    if (widget.state != null){
      print('state container widget already has appstate');
      state = widget.state;
      prefs = widget.prefs; 
    } else {
      print('init state container widget appstate');
      state = AppState();
      //restoreState();
    }
    if (!kIsWeb){
      setupBGFetch();
    }
    //initNotifications();
    super.initState();
  }

  
  Future<bool> restoreState() async{ //from saved session preferences
  }

  void setupBGFetch(){
    //so far this works for app onPause (home button), but not for onStop (back button)
    /*if (Platform.isAndroid || Platform.isIOS){
      BackgroundFetch.configure(BackgroundFetchConfig(
        enableHeadless: true,
        minimumFetchInterval: prefs == null ? 15 : prefs.getInt('notify_check_interval'),
        stopOnTerminate: false,
      //), util.checkNotifications);
      ), checkNotifications);

    // BackgroundFetch.registerHeadlessTask(util.checkNotifications);
    }*/
  }
  //wait for initial state data to load
  Future<bool> waitForDoneLoading() async{
    while (state.loading == true){
      Future.delayed(Duration(seconds: 3));
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return InheritedStateContainer(
      data: this,
      child: widget.child,
    );
  }
  
  /**
   * actions for dealing with state data are here
   * each of these functions updates shared preferences and API as necessary
   *
   */
  
  /**
   * add tag to the local tag-store with the given mode
   */
  void addTag(String t, int mode){
    
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

  //empty the local tag-store
  void removeLocalTags(){
    setState(() {
      state.query.localTags.empty();
      state.feedOutdated = true;
    });
    prefs.setString('local_tags', state.query.localTags.toJSON());
  }
  
  //set whether or not this tag shall be used for the query
  void useTag(String label, bool u){
    setState(() {
      state.query.localTags.use(label, u); 
      state.feedOutdated = true;
    });
    prefs.setString('local_tags', state.query.localTags.toJSON());
  }

  //toggle whether this tag shall be used for the query
  void toggleUseTag(String label){
    setState(() {
      state.query.localTags.toggleUse(label);
      state.feedOutdated = true;
    });
    prefs.setString('local_tags', state.query.localTags.toJSON());
    prefs.setBool('feed_outdated', true);
  }

  //set whether to retrieve croaks that have all (true) or any (false) of the tags of interest
  void tagsIncludeAll(bool a){  
  }

  //retrive the most commonly-used tags in this location and put them in the local tag-store
  void getSuggestedTags(){
     
  }

  //set the radius of the query
  void setRadius(int r){
    
  }

  //currently obsolete because only using km
  void setDistUnit(int u){
    setState(() {
      state.query.distUnit = u;
      state.feedOutdated = true;
    });
    prefs.setBool('feed_outdated', true);
  }

  //get the user's location and update its value in the app state
  void getLocation(){
  }


  //set how long between e
  void setNotificationInterval(int ni){
  }

  //toggle if background process will check for replies of given croak to notify user
  void toggleSubscribe(int id){
    setState(() {
      state.localCroaks.toggleSubscribe(id);  
    });
    prefs.setString('local_croaks', state.localCroaks.toJSON());
    print(state.localCroaks.get(id).toString());
  }

  //unsubscribe from all croaks
  void unsubAll(){
    setState(() {
      state.localCroaks.getListeningIDs().forEach((l){
        state.localCroaks.unsub(l);
      });
    });
    prefs.setString('local_croaks', state.localCroaks.toJSON());
  }

  //get croaks, taking into account last fetched to decide if need api call
  Future<List> getFeed(bool forceAPI) async{ //TODO for replies too?
    List res;
    if (forceAPI || state.lastCroaksGet['0'] == null || DateTime.now().millisecondsSinceEpoch - state.lastCroaksGet['0'] > CROAKS_GET_TIMEOUT){
      gotFeed( await util.getCroaks(state.query, state.location) );
    } 
    res = List.from(state.localCroaks.croaks);
    
    return res;
  }

  //retrive croaks from API or shared prefs, use pid=0 for main feed, otherwise the id of the croak of which you want to retrieve comments (parent id)
  Future<List> getCroaks(bool forceAPI, int pid) async {
  }

  /** 
   * replies have been retrieved, so add them to local croak-store and shared prefs, and update when-last-updated for the parent croak
   * @param r = list of replies; parent id is derived from one element
   * */
  void gotReplies(List r){
  }

  //main croak feed has been retreived, so update local croak-store and shared prefs, and update when-last-updated
  void gotFeed(List c){
    state.lastCroaksGet['0'] = DateTime.now().millisecondsSinceEpoch;
    prefs.setString('last_croaks_get', jsonEncode(state.lastCroaksGet.map( (id, t) => MapEntry(id.toString(), t) ) ));
    prefs.setBool('feed_outdated', false);
    //prefs.setString('feed_croaks', jsonEncode(state.feed));
    if (c==null) return;
    state.localCroaks.croaks.removeWhere((lc){ //removing croaks that have been deleted from server
      return !c.map((e)=>e['id']).toList().contains(lc['id']);
    });
    state.localCroaks.add(c, true, false);
    prefs.setString('local_croaks', state.localCroaks.toJSON());
  }

  //croaks have been retrieved, either main feed or some replies, so update local croak-store, shared prefs, and update when-last-updated
  void gotCroaks(List croaks){

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
    prefs.setString('last_croaks_get', jsonEncode(state.lastCroaksGet) );
    prefs.setInt('radius', state.query.radius);

    prefs.setBool('feed_outdated', false);
    //prefs.setString('feed_croaks', jsonEncode(state.feed));
    prefs.setString('local_tags', state.query.localTags.toJSON());
    prefs.setString('local_croaks', state.localCroaks.toJSON());
  }

  //uses ids of subbed-to croaks to query server to get comments. 
  //modifies 'notify_ids' of shared prefs
  void checkNotifications() async {
    if (prefs == null) prefs = await SharedPreferences.getInstance();

    LocalCroaksStore croaksStore = state.localCroaks;
    if (croaksStore == null) croaksStore = LocalCroaksStore.fromJSON(prefs.getString('local_croaks'));
    if (croaksStore.isEmpty()) return;
    List lids = croaksStore.getListeningIDs();
    if (lids.length == 0) return;
    List notifyIDs = []; //a list of ids of croaks which have new replies
    
    List replies = await util.getReplies(lids);
    if (replies == null || replies.length ==0) return; 
    print(replies.length.toString() + ' replies of croaks ' + lids.toString());
    print('REPLIES: ' + replies.toString());
    if (replies == null) {
      util.errLog('network error while getting replies');
      return;
    }
    if (replies.length == 0){ //no new replies
      return;
    }
    replies.asMap().forEach((i, reply) {
      int id = reply['id'];
      if (notifyIDs.contains(id)) return;
      List localReplies = croaksStore.repliesOf(reply['p_id']);
      print(localReplies.length.toString() + ' local replies');
      if (!localReplies.map((r)=>r['id']).contains(id)){
        notifyIDs.add(reply['p_id']);
        croaksStore.setUnread(reply['p_id']);
        croaksStore.add(reply, false, false);
        croaksStore.get(reply['p_id'])['replies'] += 1;
      }
    });
    prefs.setString('notify_ids', jsonEncode(notifyIDs)); //REFAC feel like this shouldn't be done separately like this
    prefs.setString('local_croaks', croaksStore.toJSON());
    print('ids of croaks which user will be notified of replies: ' + notifyIDs.toString()); 
    if (notifyIDs.length > 0) notify(notifyIDs);
    //BackgroundFetch.finish();
  }

  void notify(List ids) async{
    FlutterLocalNotificationsPlugin notificationsPlugin = new FlutterLocalNotificationsPlugin();
    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    var initializationSettingsAndroid = new AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings( ); //onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    var initializationSettings = new InitializationSettings( android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    notificationsPlugin.initialize(initializationSettings, onSelectNotification: handleSelectNotification);

    //var scheduledNotificationDateTime = new DateTime.now().add(new Duration(seconds: 5));
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails('your other channel id',
        'your other channel name', 'your other channel description', priority: Priority.high);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    NotificationDetails platformChannelSpecifics = new NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
    //await store.state.notificationsPlugin.schedule(0, 'someone has replied to you', '# frogs have croaked back since [time]', scheduledNotificationDateTime, platformChannelSpecifics);
    notificationsPlugin.show(1, 'Croak', 'You have ' + ids.length.toString() + ' comments to read!', platformChannelSpecifics, payload: jsonEncode(ids));

    //store.state.notificationsPlugin.periodicallyShow(1, 'test title', 'test body', RepeatInterval.EveryMinute, platformChannelSpecifics);
    
    //https://pub.dev/packages/flutter_local_notifications
  }

  Future handleSelectNotification(String idsStr) async{ // idsStr) async{
    List ids = jsonDecode(idsStr);
    print('handling notification selection');
    print(ids.toString());
    setState(() {
      ids.forEach((id){
        
      });
      state.feedOutdated = true;
      state.hasUnread = true;
    });
    prefs.setBool('feed_outdated', true);
    prefs.setBool('has_unread', true);
    
    //Navigator.pop(this.context);
    //Navigator.push(jsonDecode(contextJSON), MaterialPageRoute(builder: (context){ return Container(child: Text('asfd')); }));
    //await Navigator.pushReplacementNamed(context, '/notifications');
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
    var initializationSettings = new InitializationSettings( android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    state.notificationsPlugin.initialize(initializationSettings, ); //onSelectNotification: onSelectNotification);
  
    //var scheduledNotificationDateTime = new DateTime.now().add(new Duration(seconds: 5));
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails('your other channel id',
        'your other channel name', 'your other channel description', priority: Priority.high);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    NotificationDetails platformChannelSpecifics = new NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
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