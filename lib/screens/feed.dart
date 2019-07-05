import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fp/state_container.dart';
import 'package:location/location.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';

import '../models.dart';

import '../api.dart' as api;
import '../util.dart' as util;
import '../db.dart' as db;
import '../consts.dart';
import 'helpers.dart';

//feed screen passes the query down to the croakfeed, then croakfeed fetches the croaks

class FeedScreen extends StatefulWidget {

  const FeedScreen() : super();

  @override
  FeedState createState() {
    return new FeedState();
  }
}

class FeedState extends State<FeedScreen> with AutomaticKeepAliveClientMixin<FeedScreen>{
  
  StateContainerState store;
  CroakFeed croakFeed;
  bool fetching = true;
  List croaksJSON;

  @override
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    store = StateContainer.of(context);
    
    if (store.state.needsUpdate) refresh();

    if (fetching){
      return Column(
        children: [
          Text("Finding your location and gathering nearby croaks..."),
          Center(
            child: Container(
              width: 120, 
              height: 120,
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(
                      value: null,
                      semanticsLabel: 'Retreiving Croaks...',
                      semanticsValue: 'Retreiving Croaks...',
                  ),
                
              )
            
            )]
          );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Tha Pond'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              refresh();
            },
          ),
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: () => sortOptions() //TODO show sort options mini-dialog
          )
        ],
      ),
      body: Container(
        child: CroakFeed(croaksJSON)
      ),

      //still deciding whether to use button to dialog for composing croak, or separe entire screen
      /*   
      floatingActionButton: FloatingActionButton(
            child: new Icon(Icons.add),
            onPressed: makeCroak,
          ),
      */
      );
  }

  //fetch the croaks according to query
  void refresh(){
    store = StateContainer.of(context);
    setState(() {
      fetching = true;
    });
    //store.fetchCroaks(pid);
    int lcg; //don't worry about time of last update if needUpdate, for example query changed
    if (!store.state.needsUpdate) lcg = store.state.lastCroaksGet; 
    util.getCroaks(store.state.query, lcg, store.state.location).then((cks){
      List cs = List.from(cks);
      
      for (int i = 0; i < cs.length; i++){
        /* this started erroring with 'read only'
        if (cks[i]['p_id'] != null){ 
          cks.removeAt(i);
          i--;
        }
        */
        if (cs[i]['p_id'] != null){
          cs.removeAt(i);
          //i--;
        }
        if (cs[i]['p_id'] == null){
          //cs.add(List.from(cks[i]));
          
          if (cs[i]['tags'] is String){
            String tagsStr = cs[i]['tags'];
            cs[i]['tags'] = List();
            List tags = tagsStr.split(',');
            for (int j = 0; j < tags.length; j++){
              cs[i]['tags'].add({'label': tags[j]});
            } //to make compatible with CroakFeed parsing
          }

          /*
          if (cs.last['tags'] is String){
            String tagsStr = cs.last['tags'];
            cs.last['tags'] = [];
            List tags = tagsStr.split(',');
            for (int j = 0; j < tags.length; j++){
              cs.last['tags'].add({'label': tags[j]});
            } //to make compatible with CroakFeed parsing
          } */
            
        }
      }
      store.state.needsUpdate = false;
      
      store.state.lastCroaksGet = DateTime.now().millisecondsSinceEpoch;
      store.prefs.setInt('last_croaks_get', store.state.lastCroaksGet);
      if (mounted){
        setState(() {
          fetching = false;
          croaksJSON = cs;
        });
        print('feed got croaks.'); 
      }
      
    });
    
  }

  void sortOptions(){ //currently just using this function for testing
    
  }

  

  @override
  bool get wantKeepAlive => ( !fetching );
}