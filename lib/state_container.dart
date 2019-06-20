import 'package:flutter/material.dart';

import 'models.dart';
import 'util.dart' as util;

class StateContainer extends StatefulWidget{
  
  final AppState state;
  Widget child;
  

  StateContainer({
    @required this.child,
    this.state
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

  @override
  void initState(){
    if (widget.state != null){
      state = widget.state;
    } else {
      state = AppState();
    }

    super.initState();
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
      util.getCroaks(state.query).then((cks){
        
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
    return;
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