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
import 'package:toast/toast.dart';
import '../models.dart';
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
  List<Map> feed; //this is the data for the ListView, because it can be sorted unlike the croak store of the state
  LocalCroaksStore localCroaks; //of the state
  bool fetching = false;
  bool stalled = false; //don't fetch
  bool error = false; //was there an error in the most recent fetch attempt?
  Widget body;
  RefreshController refreshController = RefreshController(initialRefresh: true);
  SortMethod sortMethod = SortMethod.date_asc;
  FilterMethod filterMethod = FilterMethod.query;

  FeedState();

  @override
  void initState(){
    super.initState();
    //feed = [];
    print('initing FeedState');

  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    store = StateContainer.of(context);
    print(store.state.localCroaks.toString());
    localCroaks = store.state.localCroaks;
    /*if (store.state.newReplies){//TODO i think i can create a better design for this. 
      filterFeed();
      store.state.newReplies = false;
    } */

    //feed = store.state.localCroaks.getFeed(sortMethod);
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
        child: CroakFeed(store.state.localCroaks.croaks, refresh)
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
            PopupMenuButton( //feed filter settings
              itemBuilder: (BuildContext context) => <PopupMenuEntry<FilterMethod>>[
                PopupMenuItem(
                  child: Text('Filter your feed')
                ),
                PopupMenuItem( //only show subs or non-subs
                  value: FilterMethod.subs,
                  child: Wrap( children: [ Icon(Icons.subscriptions), Text('  Subscribed-To', style: Theme.of(context).textTheme.body1) ] ),
                ),
                PopupMenuItem( //show all croaks or use query tags?
                  value: FilterMethod.query,
                  child: Wrap( children: [ Icon(Icons.category), Text('  Query', style: Theme.of(context).textTheme.body1) ] ),
                ),
                PopupMenuItem( //only show croaks with unread comments
                  value: FilterMethod.unread,
                  child: Wrap( children: [ Icon(Icons.mail), Text('  Unread Replies', style: Theme.of(context).textTheme.body1) ] ),
                )
              ],
              icon: Icon(Icons.filter_list),
              onSelected: (fm){
                setState(() {
                  filterMethod = fm;
                });
                filterFeed();
              },

              
            ),
            PopupMenuButton( //feed sort settings
              itemBuilder: (BuildContext context) => <PopupMenuEntry<SortMethod>>[
                PopupMenuItem(
                  child: Text('Sort your feed')
                ),
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
                PopupMenuItem<SortMethod>(
                  value: SortMethod.pop_asc,
                  child: Wrap( children: [ Icon(Icons.arrow_upward), Text('Replies') ] ),
                ),
                PopupMenuItem<SortMethod>(
                  value: SortMethod.pop_des,
                  child: Wrap( children: [ Icon(Icons.arrow_downward), Text('Replies') ] ),
                ),
              ],
              onSelected: (v){
                setState(() {
                  sortFeed(v);
                });
              },
              icon: Icon(Icons.sort),
            ),
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
    error = false;
    stalled = false;
    fetchCroaks(true);
  }

  void fetchCroaks(bool force){
    if (stalled || fetching) return;
    setState((){
      fetching = true;
    });

    util.getCroaks(filterMethod == FilterMethod.query ? store.state.query : new Query(), (force || store.state.feedOutdated) ? 0 : store.state.lastCroaksGet[0], store.state.location).then((res){
      
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
      
      setState((){
        fetching = false;
        stalled = true;
        error = false;
      });
      store.gotFeed(res);
      setState(() {
        body = body;
      });
      localCroaks.croaks.forEach((c){
        if (c['feed'] || c['p_id'] == 0) c['vis'] = true;
      });
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

  void displayUnread(){
    setState(() {
      fetching = false;
      stalled = true;
      error = false;
      feed = store.state.localCroaks.getHasUnread();
    });
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

  void sortFeed(SortMethod mthd){
    // sort methods: date, proximity, popularity 
    switch(mthd){
      case SortMethod.date_asc:
        localCroaks.croaks.sort((a, b){
          return b['created_at'].compareTo(a['created_at']);
        });  
        break;
      case SortMethod.dist_asc:
        localCroaks.croaks.sort((a, b){
          return a['distance'].toInt() - b['distance'].toInt();
        });
        break;
      case SortMethod.pop_asc:
        localCroaks.croaks.sort((a, b){
          return a['replies'] - b['replies'];
        });
        break;
      case SortMethod.score_asc:
        localCroaks.croaks.sort((a, b){
          return a['score'] - b['score'];
        });
        break;
      case SortMethod.sub_asc:
        localCroaks.croaks.sort((a, b){
          return a['listen'] && !b['listen'] ? 1 : -1;
        });
        break;
      case SortMethod.date_des:
        localCroaks.croaks.sort((a, b){
          return a['created_at'].compareTo(b['created_at']);
        });  
        break;
      case SortMethod.dist_des:
        localCroaks.croaks.sort((a, b){
          return b['distance'].toInt() - a['distance'].toInt();
        });
        break;
      case SortMethod.pop_des:
        localCroaks.croaks.sort((a, b){
          return b['replies'] - a['replies'];
        });
        break;
      case SortMethod.score_des:
        localCroaks.croaks.sort((a, b){
          return b['score'] - a['score'];
        });
        break;
      case SortMethod.sub_des:
        localCroaks.croaks.sort((a, b){
          return b['listen'] && !a['listen'] ? 1 : -1;
        });
        break;
    }
  }
  
  void notifyUnread(){
    Toast.show('You have unread comments', context);
    print('FEED HAS UNREAD');
  }

  //i know that this method uses a class var whereas sortFeed() uses arg. it is easier to do it this way for filtering
  void filterFeed(){ 
    localCroaks.croaks.forEach((c)=>c['vis']=true);
    if (filterMethod == FilterMethod.query){
      Query q = store.state.query;
      //setState(() {
        localCroaks.croaks.forEach((c){ //this logic is convoluted, but just setting feed = localCroaks.ofQuery(q) doesn't work for some reason
          if (localCroaks.ofQuery(q).map((e)=>e['id']).contains(c['id'])) c['vis'] = true;
          else c['vis'] = false;  
        });
      //});
      Toast.show('Showing Query Result', context);
    } else if (filterMethod == FilterMethod.subs){
      //setState((){
        localCroaks.croaks.forEach((c){
          if (c['listen']==true) c['vis'] = true;
          else c['vis'] = false;
        });
      //});
      Toast.show('Showing Subscribed-To Croaks', context);
    } else if (filterMethod == FilterMethod.unread){
      //setState(() {
        localCroaks.getHasUnread().forEach((c){
          c['vis'] = true;
          c['feed'] = true;
          if (!feed.contains(c)) feed.add(c);
          print(c);
        });
        
        localCroaks.croaks.forEach((c){
          if (c['has_unread']) c['vis'] = true;
          else c['vis'] = false;
        });
      //});
      Toast.show('Showing Subscribed-To Croaks with new Replies', context);
    }
  }

  @override
  bool get wantKeepAlive => ( !fetching );
}