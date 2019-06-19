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

  @override
  void initState(){
    super.initState();
    
  }

  @override
  Widget build(BuildContext context) {
    
    store = StateContainer.of(context);
    croakFeed = CroakFeed(context: context, pid: null);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Tha Pond'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              store.fetchCroaks(null);
            },
          ),
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: () => sortOptions() //TODO show sort options mini-dialog
          )
        ],
      ),
      body: Container(
        child: croakFeed
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

  void sortOptions(){ //currently just using this function for testing
    
  }

  

  @override
  bool get wantKeepAlive => true;
}