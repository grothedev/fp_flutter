import 'dart:math';

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
  bool fetching;
  List croaksJSON;
  bool stalled = false; //show a refresh button and don't fetch
  Widget body;

  @override
  void initState(){
    fetching = true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    store = StateContainer.of(context);
    
    if (store.state.needsUpdate) refresh();

    if (fetching){
      body = Column(
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
              
            ),
          ]
      );
    } else {
      body = Container(
        child: CroakFeed(croaksJSON)
      );
    }

    if (stalled){
      return Center(
          child: RaisedButton(
            child: Text('Refresh'),
            onPressed: () => refresh(),
          ),
          heightFactor: 10,
      );
    }

    return Scaffold(
      appBar: AppBar(
        //title: ScreenTitle('Tha Pond'),
        title: Text('Tha Pond'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              refresh();
            },
          ),
          PopupMenuButton(
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortMethod>>[
              PopupMenuItem<SortMethod>(
                value: SortMethod.date_asc,
                child: Wrap( children: [ Icon(Icons.arrow_upward), Text('Time') ] ),
              ),
              PopupMenuItem<SortMethod>(
                value: SortMethod.date_des,
                child: Wrap( children: [ Icon(Icons.arrow_downward), Text('Time') ] ),
              ),
              PopupMenuItem<SortMethod>(
                value: SortMethod.dist_asc,
                child: Wrap( children: [ Icon(Icons.arrow_upward), Text('Distance') ] ),
              ),
              PopupMenuItem<SortMethod>(
                value: SortMethod.dist_des,
                child: Wrap( children: [ Icon(Icons.arrow_downward), Text('Distance') ] ),
              ),
              PopupMenuItem<SortMethod>(
                value: SortMethod.score_asc,
                child: Wrap( children: [ Icon(Icons.arrow_upward), Text('Score') ] ),
              ),
              PopupMenuItem<SortMethod>(
                value: SortMethod.score_des,
                child: Wrap( children: [ Icon(Icons.arrow_downward), Text('Score') ] ),
              ),
              
            ],
            onSelected: (v){
              sortOptions(v);
            },
          )
        ],
      ),
      body: body

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
      store.state.needsUpdate = false;
      if (cks == null){
        print('failed to fetch croaks');
        Scaffold.of(context).showSnackBar(SnackBar(content: Text('There was a problem while attempting to fetch croaks') ));
        setState(() {
          fetching = false;
          stalled = true;
        });
        return;
      }
      if (cks.length == 0){
        Scaffold.of(context).showSnackBar(SnackBar(content: Text('There are no croaks within this area')));
        setState(() {
          fetching = false;
          stalled = true;
        });
        return;
      }
      List cs = List.from(cks);
      //removing croaks which are comments (actually this should probably be dealt with on server)
      cs = cs.where( (c) => c['p_id'] == null || c['p_id'] == 0  ).toList(); 
      for (int i = 0; i < cs.length; i++){
        
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
          stalled = false;
          croaksJSON = cs;
        });
        print('feed got croaks.'); 
      }
      
    }).timeout(new Duration(seconds: 15), 
        onTimeout: (){
          print('timed out while fetching croaks');
          Scaffold.of(context).showSnackBar(SnackBar(content: Text('Unable to Reach Server to Fetch Croaks') ));
          setState(() {
            fetching = false;
            stalled = true;
          });
        }
      );
    
  }

  void sortOptions(SortMethod mthd){ //currently just using this function for testing
    // sort methods: date, proximity, popularity 
    switch(mthd){
      case SortMethod.date_asc:
        setState(() {
          croaksJSON.sort((a, b){
            return a['created_at'].compareTo(b['created_at']);
          });  
        });
        break;
      case SortMethod.dist_asc:
        setState(() {
          croaksJSON.sort((a, b){
            print((a['distance'] - b['distance']).toString());
            return a['distance'].toInt() - b['distance'].toInt();
          });
        });
        break;
      case SortMethod.score_asc:
        setState(() {
          croaksJSON.sort((a, b){
            return a['replies'] - b['replies'];
          });
        });
        break;
      case SortMethod.date_des:
        setState(() {
          croaksJSON.sort((a, b){
            return b['created_at'].compareTo(a['created_at']);
          });  
        });
        break;
      case SortMethod.dist_des:
        setState(() {
          croaksJSON.sort((a, b){
            return b['distance'].toInt() - a['distance'].toInt();
          });
        });
        break;
      case SortMethod.score_des:
        setState(() {
          croaksJSON.sort((a, b){
            return b['replies'] - a['replies'];
          });
        });
        break;
    }
  }

  

  @override
  bool get wantKeepAlive => ( !fetching );
}