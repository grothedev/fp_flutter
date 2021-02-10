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

import 'package:FrogPond/consts.dart';
import 'package:FrogPond/controllers/croakcontroller.dart';
import 'package:FrogPond/helpers/croakfeed2.dart';
import 'package:FrogPond/state_container.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class FeedScreen extends StatefulWidget {
  @override
  FeedState createState() {
    return new FeedState();
  }
  
}

class FeedState extends State<FeedScreen> with AutomaticKeepAliveClientMixin<FeedScreen>{
  
  StateContainerState store;
  CroakController croakCtrlr;
  Future<List> feedFuture;
  FilterMethod filterMethod = FilterMethod.query;
  CroakFeed croakFeedListView;
  Widget body;
  bool loading = true;


  @override
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context){
    croakCtrlr = Provider.of<CroakController>(context);
    body = feedWidget(false); //Obx(() => CroakFeed(croakCtrlr.feed()));

    return Scaffold(
      
      appBar: AppBar(
        title: Text('The Pond'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: (){
              setState(() {
                body = feedWidget(true);
              });
            },
          ),
          PopupMenuButton(
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
              setState(() {
                //TODO filter
              });
            },
          ),
          
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
                //TODO sortFeed(v);
              },
              icon: Icon(Icons.sort),
            ),
        ]
      ),
      body: body
    );
  }

  void refreshFeed(bool forceAPI){
    setState(() {
      body = feedWidget(forceAPI);
    });
  }
  
  Widget feedWidget(bool forceAPI){
    /*
    if (store.state.loading){
      return FutureBuilder(
        future: store.waitForDoneLoading(),
        builder: (BuildContext bc, AsyncSnapshot<bool> snapshot){
          if (snapshot.hasData && snapshot.data == true){
            return feedWidget(forceAPI);
          } else {
            return loadingWidget();
          }
        }
      );
    } else {*/
    feedFuture = null;
    feedFuture = Future<List>(()=>croakCtrlr.getCroaks(false, 0));
      return FutureBuilder<List>(
        future: feedFuture,
        builder: (BuildContext bc, AsyncSnapshot<List> snapshot){
           if (snapshot.hasData && snapshot.data != null){
            return Container(
              width: MediaQuery.of(bc).size.width,
              height: MediaQuery.of(bc).size.height,
              child: SmartRefresher(
                child: CroakFeed(List<Map>.from(croakCtrlr.croakStore.ofQuery(croakCtrlr.state.query)) ),
                controller: RefreshController(initialRefresh: false),
                enablePullDown: true,
                onRefresh: (){
                  setState(() {
                    body = feedWidget(true);
                  });
                },
              )
            );
          } else if (snapshot.hasError){
            return Container(
              child: Text('Error: ' + snapshot.error.toString())
            );
          } 
          return loadingWidget();
        },
        initialData: null
      );
    //}
  }

  /**
   * @return loading screen for fetching data
   */
  Widget loadingWidget(){
    return Column(
        children: [
          Text("Fetching Croaks..."),
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
  }

  @override
  bool get wantKeepAlive => true;
  
}