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

import 'package:FrogPond/helpers/croakfeed.dart';
import 'package:FrogPond/state_container.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../consts.dart';

//feed screen presents a CroakFeed widget which contains the desired croaks based on filter method and sort method
class FeedScreen extends StatefulWidget {

  FeedScreen() : super();

  @override
  FeedState createState() {
    return new FeedState();
  }
}

/*
  responsibilities:
    - use store function to get appropriate croaks from LCS, based on filter
    - present a croak feed containing them
    - 
*/
class FeedState extends State<FeedScreen> with AutomaticKeepAliveClientMixin<FeedScreen>{
  
  StateContainerState store;
  bool loading = true; //waiting to get croaks from the store
  List feed;
  FilterMethod filterMethod = FilterMethod.query;
  Widget croakListWidget;

  @override
  void initState(){

  }

  @override
  Widget build(BuildContext context){
    store = StateContainer.of(context);
    if (feed == null) {
      refreshFeed(false);
    }
    croakListWidget = new CroakFeed(feed, ()=>refreshFeed(true));
    Widget body;
    if (loading){
      body = Column(
          children: [
            Text("Fetching croaks..."),
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
        child: croakListWidget,
      );
    }
    return Scaffold(
      appBar: AppBar(
          title: Text('The Pond'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                refreshFeed(true);
              },
            ),
            /*
            PopupMenuButton( //feed filter settings
              itemBuilder: (BuildContext context) => <PopupMenuEntry<FilterMethod>>[
                PopupMenuItem(
                  child: Text('Filter your feed')
                ),
                
                PopupMenuItem( //only show subs or non-subs
                  value: FilterMethod.subs,
                  child: Wrap( children: [ Icon(Icons.subscriptions), Text('  Subscribed-To', style: Theme.of(context).textTheme.bodyText1) ] ),
                ),
                PopupMenuItem( //show all croaks or use query tags?
                  value: FilterMethod.query,
                  child: Wrap( children: [ Icon(Icons.category), Text('  Query', style: Theme.of(context).textTheme.bodyText1) ] ),
                ),
                PopupMenuItem( //only show croaks with unread comments
                  value: FilterMethod.unread,
                  child: Wrap( children: [ Icon(Icons.mail), Text('  Unread Replies', style: Theme.of(context).textTheme.bodyText1) ] ),
                )
              ],
              icon: Icon(Icons.filter_list),
              onSelected: (fm){
                this.filterMethod = fm;
                //refreshFeed(false);
                filterFeed();
              },
            ),
            */
            PopupMenuButton( //feed sort settings
              itemBuilder: (BuildContext context) => <PopupMenuEntry<SortMethod>>[
                PopupMenuItem(
                  child: Text('Sort your feed')
                ),
                PopupMenuItem<SortMethod>(
                  value: SortMethod.date_asc,
                  child: Wrap( children: [ Icon(Icons.arrow_upward, color: Colors.green), Text('Time') ] ),
                ),
                PopupMenuItem<SortMethod>(
                  value: SortMethod.date_des,
                  child: Wrap( children: [ Icon(Icons.arrow_downward, color: Colors.green), Text('Time') ] ),
                ),
                PopupMenuItem<SortMethod>(
                  value: SortMethod.dist_asc,
                  child: Wrap( children: [ Icon(Icons.arrow_upward, color: Colors.green), Text('Distance') ] ),
                ),
                PopupMenuItem<SortMethod>(
                  value: SortMethod.dist_des,
                  child: Wrap( children: [ Icon(Icons.arrow_downward, color: Colors.green), Text('Distance') ] ),
                ),
                PopupMenuItem<SortMethod>(
                  value: SortMethod.score_asc,
                  child: Wrap( children: [ Icon(Icons.arrow_upward, color: Colors.green), Text('Score') ] ),
                ),
                PopupMenuItem<SortMethod>(
                  value: SortMethod.score_des,
                  child: Wrap( children: [ Icon(Icons.arrow_downward, color: Colors.green), Text('Score') ] ),
                ),
                PopupMenuItem<SortMethod>(
                  value: SortMethod.pop_asc,
                  child: Wrap( children: [ Icon(Icons.arrow_upward, color: Colors.green), Text('Replies') ] ),
                ),
                PopupMenuItem<SortMethod>(
                  value: SortMethod.pop_des,
                  child: Wrap( children: [ Icon(Icons.arrow_downward, color: Colors.green), Text('Replies') ] ),
                ),
              ],
              onSelected: (v){
                sortFeed(v);
              },
              icon: Icon(Icons.sort),
            ),
          ],
        ),
        body: body
    );
  }

  void refreshFeed(bool forceAPI){
    setState(() {
      loading = true;  
      croakListWidget = Text("test2");
    });
    store.getFeed(forceAPI).then((f){
      setState(() {
        feed = f; 
        //croakListWidget = new CroakFeed(f, ()=>refreshFeed(true));
        loading = false;
      });
    });
  }

  /**
 * use global filtermethod. 
 */
  List filterFeed(){
    setState(() {
      switch (filterMethod){
        case FilterMethod.query: //only show croaks that would match the search query
          feed = store.state.localCroaks.ofQuery(store.state.query); 
          croakListWidget = new CroakFeed(feed, ()=>refreshFeed(true));
          break;
        case FilterMethod.subs: //only show croaks that the user is subscribed to
          feed = [{'content': 'ay yo'}]; //List.from(f.where((c) => c['listen']));
          croakListWidget = new CroakFeed(feed, null);
          break;
        case FilterMethod.unread: //only show croaks that the user is subscribed to that have new replies
          feed = store.state.localCroaks.getUnread();//feed.where((c) => c['has_unread']).toList();
          croakListWidget = new CroakFeed(feed, ()=>refreshFeed(true));
          break;
      }  
    });
    
  }



  void sortFeed(SortMethod sm){
    setState(() {
      switch(sm){
      case SortMethod.date_asc:
        feed.sort((a,b){
          DateTime da = DateFormat('yyyy-MM-d HH:mm').parse(a['created_at']).toLocal();
          DateTime db = DateFormat('yyyy-MM-d HH:mm').parse(b['created_at']).toLocal();
          return da.compareTo(db);
        });
        break;
      case SortMethod.date_des:
        feed.sort((a,b){
          DateTime da = DateFormat('yyyy-MM-d HH:mm').parse(a['created_at']).toLocal();
          DateTime db = DateFormat('yyyy-MM-d HH:mm').parse(b['created_at']).toLocal();
          return db.compareTo(da);
        });
        break;
      case SortMethod.dist_asc:
        if (store.state.query.radius == null || store.state.location == null) break;
        feed.sort((a,b)=>(a['distance']-b['distance']).round());
        break;
      case SortMethod.dist_des:
        if (store.state.query.radius == null || store.state.location == null) break;
        feed.sort((a,b)=>(b['distance']-a['distance']).round());
        break;
      case SortMethod.pop_asc:
        feed.sort((a,b)=>a['replies'] - b['replies']);
        break;
      case SortMethod.pop_des:
        feed.sort((a,b)=>b['replies'] - a['replies']);
        break;
      case SortMethod.score_asc:
        feed.sort((a,b)=>a['score']-b['score']);
        break;
      case SortMethod.score_des:
        feed.sort((a,b)=>b['score']-a['score']);
        break;
      }  
    });
    
 }
  

  @override
  bool get wantKeepAlive => true;
}