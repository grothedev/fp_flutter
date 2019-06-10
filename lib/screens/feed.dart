import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

class FeedScreen extends StatefulWidget {

  const FeedScreen() : super();

  @override
  FeedState createState() {
    return new FeedState();
  }

  @override
  StatefulElement createElement(){
    StatefulElement e = super.createElement();
    //
    return e;
     
  }
}

class FeedState extends State<FeedScreen> with AutomaticKeepAliveClientMixin<FeedScreen>{
  
  List croaksJSON; //this is the same json data structure that is returned by api call 
  List<Croak> croaks;
  List tags;
  bool loading = true;
  int lastUpdated;
  
  @override
  void initState(){
    super.initState();
    retrieveCroaks();
    
  }

  @override
  Widget build(BuildContext context) {
    
    if (util.prefs.getBool('needsUpdate')) retrieveCroaks();

    if (loading){
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
            onPressed: () => retrieveCroaks(),

          ),
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: () => sortOptions()
          )
        ],
      ),
      body: Container(
        //child: ListTile.divideTiles( tiles: CroakFeed(context: context, pid: 0, croaksJSON: croaksJSON) ), //TODO make croakfeed iterable so have divider between list items
        child: CroakFeed(context: context, pid: 0, croaksJSON: croaksJSON)
      ),

      /* 
      floatingActionButton: FloatingActionButton(
            child: new Icon(Icons.add),
            onPressed: makeCroak,
          ),
      */
      );
        
  }

  @override
  bool didUpdateWidget(Widget ow){
    print('updated widget');
    return true;
  }  

  void retrieveCroaks(){
    util.getCroaks().then((cks){
      util.prefs.setBool('needsUpdate', false); //this is a less ideal way to set state as opposed to react
      for (int i = 0; i < cks.length; i++){
        if (cks[i]['p_id'] != null){ //make sure it's not a comment croak
          cks.removeAt(i);
          i--;
        }
      }
      populateListView(cks);
      
    });
  }

  void populateListView(List crks){
    print('populating list view' + crks.toString());
    setState(() {
        loading = false;
        croaksJSON = crks;
        for (int i = 0; i < croaksJSON.length; i++){
          var cj = croaksJSON[i];
          for (int j = 0; j < cj['tags'].length; j++){
            print(cj['tags'][j]['label']);
          }
        }
    });
    
  }

  void sortOptions(){ //currently just using this function for testing
    
  }

  

  @override
  bool get wantKeepAlive => true;
}