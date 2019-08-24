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

import 'package:flutter/material.dart';
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
    if (widget.state != null){
      print('state container widget already has appstate');
      state = widget.state;
      prefs = widget.prefs;
    } else {
      print('init state container widget appstate');
      state = AppState();
      restoreState();
      
    }

    super.initState();
  }

  
  void restoreState() async{ //from saved session preferences
    prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('ran_before')){
      state.lastCroaksGet = prefs.getInt('last_croaks_get');
      state.lat = prefs.getDouble('lat');
      state.lon = prefs.getDouble('lon');
      state.query.tagsIncludeAll = prefs.getBool('exclusive');
      if (state.query.tagsIncludeAll == null) state.query.tagsIncludeAll = false;
      //state.query.tags = prefs.getStringList('tags'); //tmp for dbging
      state.query.radius = prefs.getInt('radius');
      if (state.query.radius == null) state.query.radius = 15;
      state.query.localTags = new LocalTagsStore(prefs.getStringList('tags')); //NOTE: currently cant save if the tag is being used. can only save list of strings

      state.needsUpdate = prefs.getBool('needs_update');  
    } else {
      prefs.setBool('ran_before', true);     
      state.query.localTags = new LocalTagsStore(null); 
    }
    
    if (state.lat == null || state.lon == null){
      util.initLocation().then((l){
        if (l != null){
          state.location = l;
          state.lat = l.latitude;
          state.lon = l.longitude;
          prefs.setDouble('lat', state.lat);
          prefs.setDouble('lon', state.lon);
        }
        //getSuggestedTags(); don't actually need to wait for location to be gotten because phase 1 is keeping global popular tags
      });
    } else {
      print('restored lat lon from shared prefs');
      state.location = LocationData.fromMap({'latitude': state.lat, 'longitude': state.lon});
      print(state.location.latitude.toString());
      //getSuggestedTags();
    }
    //getSuggestedTags();

    if (state.needsUpdate == null) state.needsUpdate = true;
  
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
      state.needsUpdate = true;
    });
  }

  //doesn't actually remove the tag, but exludes it from query
  void removeTag(String t){
    setState((){
      state.query.localTags.get(t)['use'] = false;
      //state.query.tagsI.remove(t);
      state.needsUpdate = true; //TODO: is this flag necessary?
    });
  }

  void removeLocalTags(){
    setState(() {
      state.query.localTags.empty();
    });
  }
  
  void toggleUseTag(String label){
    setState(() {
      state.query.localTags.use(label);
      state.needsUpdate = true;
    });
  }

  void tagsIncludeAll(bool a){
    setState(() {
      //if (state.query.tags_include_all != null) state.query.tags_include_all = !state.query.tags_include_all;
      //else state.query.tags_include_all = false;
      state.query.tagsIncludeAll = a;
      state.needsUpdate = true;
      prefs.setBool('tags_include_all', state.query.tagsIncludeAll);
    });
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
    }); 
  }

  void setCroakFeed(List crks){
    setState((){
      state.feed = crks;
      state.fetchingCroaks = false;
    }); 
  }

  void setRadius(int r){
    print('store setting rad ' + r.toString());
    if (state.query.radius != r){
      setState((){
        state.query.radius = r;
        state.needsUpdate = true;
      });
    }
  }

  //currently obsolete because only using km
  void setDistUnit(int u){
    setState(() {
      state.query.distUnit = u;
      state.needsUpdate = true;
    });
  }

  void setSortMethod(int s){
    //TODO
  }

  void getLocation(){
    util.initLocation().then((l){
      setState(() {
        state.location = l;
        state.needsUpdate = true;
      });
      SharedPreferences.getInstance().then((p){
        p.setDouble('lat', l.latitude);
        p.setDouble('lon', l.longitude);
      });
    });
  }

  void needsUpdate(){ //this is just for croaks and location. i should rename it
    setState(() {
      state.needsUpdate = true;
    });
  }

  void updateReplies(){
    setState((){
      state.updateReplies = true;
    });
  }
  void gotReplies(){
    setState(() {
      state.updateReplies = false;
    });
  }

  void fetchCroaks(int pid){
    setState((){
      state.needsUpdate = false;
      state.fetchingCroaks = true;
      util.getCroaks(state.query, state.lastCroaksGet, state.location).then((cks){
        
        for (int i = 0; i < cks.length; i++){
          if (cks[i]['p_id'] != pid){ 
            cks.removeAt(i);
            i--;
          }
        }
        state.feed = cks;
        state.lastCroaksGet = DateTime.now().millisecondsSinceEpoch;
        state.fetchingCroaks = false;
      });
    });
    prefs.setInt('last_croaks_get', state.lastCroaksGet);
  }

  void croaking(){
    setState(() {
      state.croaking = true;
    });
  }

  void croaked(){
    setState(() {
      state.croaking = false;
    });
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