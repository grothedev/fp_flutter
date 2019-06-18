import 'package:flutter/material.dart';

import 'models.dart';

class StateContainer extends StatefulWidget{
  
  AppState state;
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
    });
  }
  void removeTag(String t){
    setState((){
      state.query.tags.remove(t);
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