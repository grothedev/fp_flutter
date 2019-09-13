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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../state_container.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';


import '../util.dart' as util;
import '../consts.dart';
import '../helpers/croakfeed.dart';

//feed screen fetches the croaks and passes them down to a CroakFeed widget
class FeedScreen extends StatefulWidget {

  FeedScreen() : super();

  @override
  FeedState createState() {
    return new FeedState();
  }
}

class FeedState extends State<FeedScreen> with AutomaticKeepAliveClientMixin<FeedScreen>{
  
  StateContainerState store;
  bool fetching = false;
  bool stalled = false; //don't fetch
  bool error = false; //was there an error in the most recent fetch attempt?
  Widget body;
  RefreshController refreshController = RefreshController(initialRefresh: true);
  SortMethod sortMethod = SortMethod.date_asc;

  FeedState();

  @override
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    store = StateContainer.of(context);
    if (store.state.feedOutdated) stalled = false;
    if (!stalled) fetchCroaks(false);

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
       child: CroakFeed(store.state.localCroaks.getFeed(), refresh)
     );
    }

    if (error){
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
                  refresh();
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
                  child: Wrap( children: [ Icon(Icons.arrow_upward), Text('Replies') ] ),
                ),
                PopupMenuItem<SortMethod>(
                  value: SortMethod.score_des,
                  child: Wrap( children: [ Icon(Icons.arrow_downward), Text('Replies') ] ),
                ),
                
              ],
              onSelected: (v){
                store.state.localCroaks.sort(v);
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

  
  void refresh(){
    stalled = false;
    fetchCroaks(true);
  }

  void fetchCroaks(bool force){
    
    if (stalled || fetching) return;
    setState((){
      fetching = true;
    });
    print('feed getting croaks: ' + store.state.feedOutdated.toString());
    util.getCroaks(store.state.query, (force || store.state.feedOutdated) ? 0 : store.state.lastCroaksGet, store.state.location).then((res){

      if (res == null){
        print('failed to fetch croaks');
        Scaffold.of(context).showSnackBar(SnackBar(content: Text('There was a problem while attempting to fetch croaks') ));
        setState(() {
          fetching = false;
          stalled = true;
          error = true;
        });
        refreshController.refreshCompleted();
        return;
      }
      if (res.length == 0){
        Scaffold.of(context).showSnackBar(SnackBar(content: Text('There are no croaks within this area')));
        setState(() {
          fetching = false;
          stalled = true;
          error = true;
        });
        store.state.feedOutdated = false;
        refreshController.refreshCompleted();
        return;
      }
      
      List cs = res;
      for (int i = 0; i < cs.length; i++){
        DateTime dt = DateFormat('yyyy-MM-d HH:mm').parse(cs[i]['created_at']).toLocal();
        cs[i]['timestampStr'] = dt.year.toString() + '/' + dt.month.toString() + '/' + dt.day.toString() + ' - ' + dt.hour.toString() + ':' + dt.minute.toString();
      } 
      setState((){
        fetching = false;
        stalled = true;
        error = false;
      });
      store.gotFeed(cs);
      refreshController.refreshCompleted();
    }).timeout(new Duration(seconds: 15), 
      onTimeout: (){
        print('timed out while fetching croaks');
        Scaffold.of(context).showSnackBar(SnackBar(content: Text('Unable to Reach Server to Fetch Croaks') ));
        setState(() {
          fetching = false;
          stalled = true;
          error = true;
        });
      }
    );
    store.state.feedOutdated = false;
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