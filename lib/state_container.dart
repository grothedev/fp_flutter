import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'util.dart' as util;

class StateContainer extends StatefulWidget{
  
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
  
  @override
  void initState(){
    if (widget.state != null){
      state = widget.state;
      prefs = widget.prefs;
    } else {
      state = AppState();
      SharedPreferences.getInstance().then((p){
        prefs = p;
        restoreState();
      });
    }

    super.initState();
  }

  
  void restoreState(){ //from saved session preferences
    state.lastCroaksGet = prefs.getInt('last_croaks_get');
    state.lat = prefs.getDouble('lat');
    state.lon = prefs.getDouble('lon');
    state.query.exclusive = prefs.getBool('exclusive');
    state.query.tags = prefs.getStringList('tags');
    state.query.radius = prefs.getInt('radius');
    state.needsUpdate = prefs.getBool('needs_update');

    if (state.lat == null || state.lon == null){
      util.initLocation().then((l){
        if (l != null){
          state.location = l;
          state.lat = l.latitude;
          state.lon = l.longitude;
          prefs.setDouble('lat', state.lat);
          prefs.setDouble('lon', state.lon);
        }
      });
    }

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
  void addTag(String t){
    setState((){
      state.query.tags.add(t);
      state.needsUpdate = true;
    });
  }
  void removeTag(String t){
    setState((){
      state.query.tags.remove(t);
      state.needsUpdate = true;
    });
  }

  void toggleExcusive(){
    setState(() {
      state.query.exclusive = !state.query.exclusive;
      state.needsUpdate = true;
      prefs.setBool('exclusive', state.query.exclusive);
    });
  }

  void setCroakFeed(List crks){
    setState((){
      state.feed = crks;
      state.fetchingCroaks = false;
    }); 
  }

  void needsUpdate(){
    setState(() {
      state.needsUpdate = true;
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

    /*
    util.getCroaks(state.query).then((cks){
      setState(() {
        for (int i = 0; i < cks.length; i++){
        if (cks[i]['p_id'] != pid){ 
            cks.removeAt(i);
            i--;
          }
        }
        state.feed = cks;
        state.fetchingCroaks = false;
      });    
    });
    */
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