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

    checkNotifications();

    if (widget.state != null){
      print('state container widget already has appstate');
      state = widget.state;
      prefs = widget.prefs; 
    } else {
      print('init state container widget appstate');
      state = AppState();
      restoreState();
    }
    setupBGFetch();
    //initNotifications();
    super.initState();
  }

  
  void restoreState() async{ //from saved session preferences
    prefs = await SharedPreferences.getInstance();
    print('FROGPOND RESTORING SHARED PREFS');

    if (prefs.containsKey('ran_before')){
      state.lastCroaksGet = jsonDecode( prefs.getString('last_croaks_get') );
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
      state.hasUnread = prefs.containsKey('has_unread') ? prefs.getBool('has_unread') : false;
      if (!prefs.containsKey('notify_check_interval')) prefs.setInt('notify_check_interval', 15);
      state.notifyCheckInterval = prefs.getInt('notify_check_interval');
    } else {
      prefs.setBool('ran_before', true); 
      prefs.setBool('feed_outdated', true);
      prefs.setString('last_croaks_get', jsonEncode(state.lastCroaksGet));
      state.feedOutdated = true;    
      state.query.localTags = new LocalTagsStore(null); 
      prefs.setString('local_tags', '');
      state.localCroaks = new LocalCroaksStore(null);
      prefs.setString('local_croaks', state.localCroaks.toJSON());
      prefs.setInt('notify_check_interval', 15);
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
      minimumFetchInterval: prefs == null ? 15 : prefs.getInt('notify_check_interval'),
      stopOnTerminate: false,
    //), util.checkNotifications);
    ), checkNotifications);

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
    prefs.setInt('notify_check_interval', ni);                       
  }

  void toggleSubscribe(int id){
    setState(() {
      state.localCroaks.toggleSubscribe(id);  
    });
    prefs.setString('local_croaks', state.localCroaks.toJSON());
    print(state.localCroaks.get(id).toString());
  }

  void unsubAll(){
    setState(() {
      state.localCroaks.getListeningIDs().forEach((l){
        state.localCroaks.unsub(l);
      });
    });
    prefs.setString('local_croaks', state.localCroaks.toJSON());
  }

  void gotReplies(List r){
    if (r==null || r.length == 0) return;
    setState(() {
      state.newReplies = true; //so that feed knows to hide replies. TODO maybe unnecessary
    });
    state.localCroaks.add(r, false, false);
    state.lastCroaksGet[r[0]['p_id']] = DateTime.now().millisecondsSinceEpoch;
    print('got replies: ' + state.localCroaks.repliesOf(r[0]['p_id']).toList().map((c)=>c['id']).toString());
    prefs.setString('local_croaks', state.localCroaks.toJSON());
    prefs.setString('last_croaks_get', jsonEncode(state.localCroaks));
  }

  void gotFeed(List c){
    state.lastCroaksGet[0] = DateTime.now().millisecondsSinceEpoch;
    prefs.setString('last_croaks_get', jsonEncode( state.lastCroaksGet ) ) ;
    prefs.setBool('feed_outdated', false);
    //prefs.setString('feed_croaks', jsonEncode(state.feed));
    state.localCroaks.croaks.removeWhere((lc){
      return !c.map((e)=>e['id']).toList().contains(lc['id']);
    });
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