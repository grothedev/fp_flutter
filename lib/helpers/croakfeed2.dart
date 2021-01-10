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

import 'package:FrogPond/screens/croakdetail.dart';
import 'package:flutter/material.dart';

class CroakFeed extends StatefulWidget{
  final List<Map> croaks;
  //final Function refresh;
  
  CroakFeed(this.croaks);//this.refresh, {this.pip});

  @override
  State<StatefulWidget> createState() {
    return CroakFeedState(croaks);
  }
}

class CroakFeedState extends State<CroakFeed>{
  List<Map> croaks;

  CroakFeedState(this.croaks);

  @override
  Widget build(BuildContext context) {
    if (croaks == null || croaks.length == 0){
      return Text('No croaks were heard.');
    } else {
      return Flexible(
        child: ListView.builder(
          itemBuilder: (context, i){
            return FeedItem(context, croaks[i]);
          },
        ),
        flex: 1
      );
    }
  }
}

class FeedItem extends Widget{
  Map c; //the croak in the list view
  BuildContext context;
  List tagLabels;

  FeedItem(this.context, this.c){
    tagLabels = c['tags'].map((t)=>t['label']).toList();
  }
  
  @override
  Widget build(BuildContext context){
    return new Container(
      padding: EdgeInsets.only(left: 6, right: 6),
      decoration: BoxDecoration(
        border: Border.all(
          //color: c['ip'] == pip ? Colors.green : Colors.grey,
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
                child: Text(tagLabels.join(', '), 
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

  @override
  Element createElement() {

  }

}