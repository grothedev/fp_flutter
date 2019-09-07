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

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../state_container.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';

import '../models.dart';

import '../api.dart' as api;
import '../util.dart' as util;
import '../db.dart' as db;
import '../consts.dart';

import '../helpers/croakfeed.dart';

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
  RefreshController refreshController = RefreshController(initialRefresh: false);
  SortMethod sortMethod = SortMethod.date_asc;
  
  @override
  void initState(){
    fetching = true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    store = StateContainer.of(context);
    
    if (store.state.needsUpdate) refresh(false);

    if (fetching){
      body = Column(
          children: [
            Text("Gathering nearby croaks..."),
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
       child: CroakFeed(croaksJSON, refresh)
     );
    }

    if (stalled){
      body = Container(
        padding: EdgeInsets.only(bottom: 40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('The pond is still...'),
              RaisedButton(
                child: Text('Refresh'),
                onPressed: (){
                  setState(() {
                    fetching = true;
                  });
                  refresh(true);
                },
              ),
            ]
          )
        )
      );
      /*return Center(
          child: RaisedButton(
            child: Text('Refresh'),
            onPressed: () => refresh(),
          ),
          heightFactor: 10,
      );*/
    }

    return Scaffold(
        appBar: AppBar(
          //title: ScreenTitle('Tha Pond'),
          title: Text('The Pond'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  fetching = true;
                });
                refresh(true);
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
                  child: Wrap( children: [ Icon(Icons.arrow_upward), Text('Replies') ] ),
                ),
                PopupMenuItem<SortMethod>(
                  value: SortMethod.score_des,
                  child: Wrap( children: [ Icon(Icons.arrow_downward), Text('Replies') ] ),
                ),
                
              ],
              onSelected: (v){
                sortFeedList(v);
              },
            )
          ],
        ),
        body: body

        //this would be a button to compose a new croak, but currently there is a separate screen for that
        /*   
        floatingActionButton: FloatingActionButton(
              child: new Icon(Icons.add),
              onPressed: makeCroak,
            ),
        */
    );
  }

  //fetch the croaks according to query
  void refresh(bool force){
    store = StateContainer.of(context);
    setState(() {
      fetching = true;
    });
    print('feed refreshing');
    //if(mounted) Toast.show(makeRefreshToastText(), context, duration: 8);
    
    util.getCroaks(store.state.query, force ? 0 : store.state.lastCroaksGet, store.state.location).then((cks){
      store.state.needsUpdate = false;
      if (cks == null){
        print('failed to fetch croaks');
        Scaffold.of(context).showSnackBar(SnackBar(content: Text('There was a problem while attempting to fetch croaks') ));
        setState(() {
          fetching = false;
          stalled = true;
        });
        refreshController.refreshCompleted();
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
        DateTime dt = DateFormat('yyyy-MM-d HH:mm').parse(cs[i]['created_at']).toLocal();
        cs[i]['timestampStr'] = dt.year.toString() + '/' + dt.month.toString() + '/' + dt.day.toString() + ' - ' + dt.hour.toString() + ':' + dt.minute.toString();
        

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
        sortFeedList(sortMethod);
        print('feed got croaks.'); 
      }
      setState(() {
        fetching = false;
      });
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

  void sortFeedList(SortMethod mthd){
    // sort methods: date, proximity, popularity 
    switch(mthd){
      case SortMethod.date_asc:
        setState(() {
          croaksJSON.sort((a, b){
            return b['created_at'].compareTo(a['created_at']);
          });  
        });
        break;
      case SortMethod.dist_asc:
        setState(() {
          croaksJSON.sort((a, b){
            return a['distance'].toInt() - b['distance'].toInt();
          });
        });
        break;
      case SortMethod.pop_asc:
        setState(() {
          croaksJSON.sort((a, b){
            return a['replies'] - b['replies'];
          });
        });
        break;
      case SortMethod.score_asc:
        setState(() {
          croaksJSON.sort((a, b){
            return a['score'] - b['score'];
          });
        });
        break;
      case SortMethod.date_des:
        setState(() {
          croaksJSON.sort((a, b){
            return a['created_at'].compareTo(b['created_at']);
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
      case SortMethod.pop_des:
        setState(() {
          croaksJSON.sort((a, b){
            return b['replies'] - a['replies'];
          });
        });
        break;
      case SortMethod.score_des:
        setState(() {
          croaksJSON.sort((a, b){
            return b['score'] - a['score'];
          });
        });
        break;
    }
  }


  //toast text to display info about the query upon refresh
  String makeRefreshToastText(){
    String t = 'Getting croaks';
    var q = store.state.query;
    if (q.radius != null){
      t += ' within ' + q.radius.toString() + ' km of you';
    }
    if (q.localTags != null && q.localTags.getActiveTagsLabels().length > 0){
      t += ' which are associated with ';
      q.tagsIncludeAll ? t += 'all ' : t += 'some ';
      t += 'of the following tags: ' + q.localTags.getActiveTagsLabels().join(', ');  
    } 
    /*
    if (q.tagsE.length > 0){
      t += ' and which are not associated with any of the following tags: ' + q.tagsI.join(', ');
    }
    */
    t += '.';

    return t;
  }

  

  @override
  bool get wantKeepAlive => ( !fetching );
}