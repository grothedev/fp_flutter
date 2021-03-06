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


import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../state_container.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../screens/croakdetail.dart';

class CroakFeed extends StatefulWidget{
  final List croaksJSON;
  final Function refresh;
  final String pip; //ip address of parent croak, to check for replies by OP

  CroakFeed(this.croaksJSON, this.refresh, {this.pip});

  @override
  State<StatefulWidget> createState() {
    return CroakFeedState(croaksJSON, refresh, pip: pip);
  }
}

class CroakFeedState extends State<CroakFeed>{
  List listItems = [];
  List croaks;
  List<bool> favs;
  StateContainerState store;
  RefreshController refreshController = RefreshController(initialRefresh: false);
  Function refresh;
  String pip;
  Map ip_color = {};

  CroakFeedState(List croaksJSON, this.refresh, {this.pip}){
    favs = new List<bool>();
    this.croaks = croaksJSON;
    print('constructing CroakFeed');
  }

  @override
  void initState(){
    super.initState();
    
    if (pip == null) return; //only do color association if this is a comment thread
    for (var c in listItems){
      if (!ip_color.keys.contains(c['ip'])) ip_color[c['ip']] = Color(Random().nextInt(0xAA + 1<<24)); 
      //c['color'] = ip_color[c['ip']]; //don't associate color with data model (that causes problems with JSON encoding)
    }
  }

  @override
  Widget build(BuildContext context) {
    print('building CroakFeed');
    //listItems = croaks.where((c)=>c['vis']==true).toList();
    listItems = List.from(croaks);
    return SmartRefresher(
        enablePullDown: true,
        enablePullUp: false,
        controller: refreshController,
        onRefresh: refresh,
        child: ListView.builder(
            //itemCount: croaksJSON == null ? 0 : croaksJSON.length,
            itemCount: listItems.length,
            itemBuilder: (context, i) {
              return new Container(
                child: feedItem(i),
              );
            },
            shrinkWrap: true,    
         )
      );
  }

  Widget feedItem(id){
    Map item = listItems[id];
    List tags = [];
    if (item['tags'] != null){
      for (int j = 0; j < item['tags'].length; j++){
        tags.add(item['tags'][j]['label']);
      }
    }

    favs.add(false);
    Map c = item;

    return new Container(
      padding: EdgeInsets.only(left: 6, right: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: c['ip'] == pip ? Colors.green : Colors.grey,
          //color: c['color'],
          width: .3,
        ),
      ),
      child: ListTile(
        dense: false,
        leading: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black12
            ),
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              c['has_unread'] ? Text( '!', style: Theme.of(context).textTheme.subtitle2) : Text( c['replies'].toString(), style: Theme.of(context).textTheme.caption),
              Text('replies', style: Theme.of(context).textTheme.subtitle2,)
            ],
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
        ),
        title: RichText(
          text: TextSpan( 
            text: c['content'],
            style: Theme.of(context).textTheme.bodyText2,
          ),
          maxLines: 8,
          overflow: TextOverflow.clip,
        ),
        trailing: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black12
            ),
            shape: BoxShape.circle
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text( c['score'].toString(), style: Theme.of(context).textTheme.caption),
              Text('points', style: Theme.of(context).textTheme.subtitle2)
            ],
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
        ),
        subtitle: Container(
          margin: EdgeInsets.only(top: 2),
          child: Row(
            children: <Widget>[
              c.containsKey('distance') ? 
                                Text(c['timestampStr'] + '; ' + c['distance'].toInt().toString() + ' km', style: Theme.of(context).textTheme.subtitle1,)
                                : Text(c['timestampStr'], style: Theme.of(context).textTheme.subtitle1),
              Spacer(
                flex: 2
              ),
              c['p_id'] == null ? //only show tags for root feed
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .3), 
                child: Text(tags.join(', '), 
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.caption
                      )
                  
              ) 
              : Container()
            
            ]
          ),
        ),
        onTap: (){
          Navigator.push(this.context, MaterialPageRoute(
            builder: (context) => CroakDetailScreen(c)
          ));
        },
        contentPadding: EdgeInsets.all(1),
        onLongPress: ((){ 
          return; //TODO position this properly
          showMenu(
            context: context,
            position: RelativeRect.fromSize(Rect.fromLTWH(20, 30, 400, 300), Size.fromHeight(400)),
          
            items: <PopupMenuEntry>[
              PopupMenuItem(
                value: 'cl_copy-content',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.content_copy),
                    Text("Copy to Clipboard"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'cl_upvote',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.arrow_upward),
                    Text("up-vote"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'cl_downvote',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.arrow_downward),
                    Text("down-vote"),
                  ],
                ),
              )
            ],
          );

          /*
          Clipboard.setData(ClipboardData(text: c['content']));
          Toast.show('Croak content copied to clipboard', context);
          */
        }),
      )
      );
  }

  void updateFeed(List f){
    setState(() {
      this.croaks = List.from(f);
    });
  }

  //toggles "favorite" or normal for a croak  
  void fav(int id){
    setState((){
      favs[id] = !favs[id];
    });
  }

}

//pop-up of list of actions when long press a croak on the feed. currently unused as there is only one option (copy). what other options should there be? copy url as well
class FeedItemOptionsDialog extends Dialog{
  @override
  Widget build(BuildContext context){
    return SimpleDialog(
      children: [
        
      ]
    );
  }
}