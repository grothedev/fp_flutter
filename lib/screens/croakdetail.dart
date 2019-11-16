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

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:toast/toast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../state_container.dart';
import '../util.dart' as util;
import '../api.dart' as api;

import '../helpers/composecroakdialog.dart';
import '../helpers/croakfeed.dart';

final String ro_url_pre = 'http://' + api.host + ':' + api.port.toString() + '/c/'; //prefix of url for fancy read-only webview


class CroakDetailScreen extends StatefulWidget{
  Map c;

  CroakDetailScreen(Map c){
    this.c = c;
  }

  @override
  State<StatefulWidget> createState() {
    return CroakDetailState(c);
  }
  
}

class CroakDetailState extends State<CroakDetailScreen>{

  Map c;
  final contentController = TextEditingController();
  final fk = GlobalKey<FormState>();// form key
  List replies;
  String subToggleText;
  StateContainerState store;

  //this stuff is now in the compose croak dialog
  //final replyController = TextEditingController();
  //final fk = GlobalKey<FormState>();// form key
  //bool anon = true;

  CroakDetailState(Map c){
    this.c = c;
    if (c.containsKey('listen') && c['listen']){
      subToggleText = 'Subscribe';
    } else {
      subToggleText = 'Unsubscribe';
    }
  }

  @override
  void initState(){
    super.initState(); 
    getReplies(); 
  }


  @override
  Widget build(BuildContext context) {
    store = StateContainer.of(context);
    print(c['files'].toString());
    List tags = [];
    for (int j = 0; c['tags'] != null && j < c['tags'].length; j++){
      tags.add(c['tags'][j]['label']);
    }

    if (store.state.updateReplies) getReplies();

    String croakURL = ro_url_pre+c['id'].toString();
    return Scaffold( 
        appBar: AppBar(
          title: c['p_id'] == null || c['p_id'] == 0 ? Text(c['timestampStr']) 
          : Row(
            children: [
              Text(c['timestampStr'] + ' ; Reply to '),
              IconButton(
                tooltip: c['timestampStr'] + ' ; Reply to ' + c['p_id'].toString(),
                icon: Icon(Icons.arrow_upward),
                onPressed: (){
                  Navigator.push(this.context, MaterialPageRoute(
                    builder: (context) => CroakDetailScreen(store.state.localCroaks.get(c['p_id']))
                  ));
                },
              ),
            ]
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.share),
              onPressed: (){
                Clipboard.setData(ClipboardData(text: croakURL));
                Toast.show('URL copied to clipboard', context);
              },
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: (){
                getReplies();
              },
            ),
            IconButton(
              icon: Icon(Icons.report),
              onPressed: (){
                reportCroak();
              },
              tooltip: 'Report Illegal Content or Spam',
            ),
            IconButton( //TODO fix initial switch position
              icon: c['listen'] ? Icon(MdiIcons.toggleSwitch) : Icon(MdiIcons.toggleSwitchOff),
              onPressed:(){
                toggleSubscribe();
              },
              tooltip: c['listen'] ? 'UnSubscribe' : 'Subscribe',      
            )
          ],
          
        ),
        body: Column(
          children: [
            Container( //CONTENT
              padding: EdgeInsets.all(6),
              margin: EdgeInsets.all(4),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                  style: BorderStyle.solid,
                  width: 1
                )
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * .5
                ),
                child: SingleChildScrollView(
                  child: Linkify(text: c['content'], onOpen: (link)=>{ launch(link.url) }, )
                )
              ),                                                                                                                                                                          
            ),

            ConstrainedBox( //TAGS
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * .1
              ),
              child: Text(tags.join(', '), style: Theme.of(context).textTheme.subhead),
            ),

            c['files'] != null && c['files'].length > 0 ? //FILE
            fileView(c['files']) : Center(),

            Container( //DIVIDER
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                )
              ),
              margin: EdgeInsets.only(top: 10, bottom: 2),
            ),

            Container(  //VOTE BUTTONS
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  
                  RaisedButton(
                    child: Icon(Icons.arrow_downward),
                    onPressed: () => util.vote(false, c['id']).then((s){
                      setState(() {
                        c['score'] = s;
                      });
                    }),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: Text(c['score'].toString(), style: Theme.of(context).textTheme.body1),
                  ),
                  RaisedButton(
                    child: Icon(Icons.arrow_upward),
                    onPressed: () => util.vote(true, c['id']).then((s){
                      setState(() {
                        c['score'] = s;
                      });
                    }),
                  ),
                ]
              )
            ),

            Container( //DIVIDER
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                )
              ),
              margin: EdgeInsets.only(bottom: 12.0),
            ),

            Expanded( //REPLIES
              key: GlobalKey(),
              flex: 1,
              child: replies != null && replies.length > 0 ? 
                CroakFeed(
                  store.state.localCroaks.repliesOf(c['id']), getReplies, pip: c['ip']
                ) :
                Text('No Replies')
            ),
          ]
        ),
                       
        //bottomSheet: Text('bottomsheet test'),
        floatingActionButton: FloatingActionButton(
          onPressed: (){
            showDialog(context: context, builder: (context) {
              return ComposeCroakDialog(c);
            });
          },
          child: Icon(Icons.reply),
          
        ),
    );
  }

  void getReplies(){
    util.getReplies(c['id']).then((r){
      //setState((){
        for (int i = 0; i < r.length; i++){
          DateTime dt = DateFormat('yyyy-MM-d HH:mm').parse(r[i]['created_at']).toLocal();
          r[i]['timestampStr'] = dt.year.toString() + '/' + dt.month.toString() + '/' + dt.day.toString() + ' - ' + dt.hour.toString() + ':' + dt.minute.toString();
        }
        this.replies = r;
      //});
      store.gotReplies(r);
    });
    c['has_unread'] = false;
  }

  void copyURL(){

  }

  Widget fileView(List files){
    String fn = files[0]['filename'].toString();
    /*if (fn.endsWith('.mp4') || fn.endsWith('.mov') || fn.endsWith('mpeg')){
      VideoPlayerController vpc = VideoPlayerController.network('http://' + api.host + '/f/' + fn);
      vpc.initialize().then((_){
        return Center(
          child: GestureDetector(
            onTap: (){
              launch('http://' + api.host + '/f/' + fn);
            },
            child: vpc.value.initialized ? 
                    VideoPlayer(vpc) :
                    Text('Loading video ...')
          )
        );  
      });
      
    }*/
    
    if (fn.endsWith('.png') || fn.endsWith('.jpg') || fn.endsWith('.gif')){
      return Container(
        height: MediaQuery.of(context).size.height * .16, //was gonna try to figure out how to adjust the size based on resolution of image
        child: Center(
          child: GestureDetector(
            onTap: (){
              launch('http://' + api.host + '/f/' + fn);
            },
            child: Image.network(
              'http://' + api.host + '/f/' + fn,
              fit: BoxFit.fitHeight,
              
            ),
          )
        ),
      );
    } else return Container(
      height: MediaQuery.of(context).size.height * .16,
      child: Center(
        child: RaisedButton(
          child: Text(c['files'][0]['filename'].toString()),
          onPressed: (){
            launch('http://' + api.host + '/f/' + c['files'][0]['filename']);
          },
        ),
      
      ),
    );
  }

  void toggleSubscribe(){
    store.toggleSubscribe(c['id']);
    c = store.state.localCroaks.get(c['id']);
    if (c['listen']){
      Toast.show('You will receive notifications when this croak is replied to', context);
    } else {
      Toast.show('You will not receive notifications when this croak is replied to', context);
    }
  }

  //if enough users report a croak, it will get removed
  void reportCroak(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        title: Text('Report this croak?', textAlign: TextAlign.center,),
        content: Text('Please only report croaks which contain illegal content or are spam.'),
        actions: [
          MaterialButton(
            child: Text('Yes'),
            onPressed: () => util.reportCroak(c['id']),
          ),
          MaterialButton(
            child: Text('No'),
            onPressed: () => Navigator.of(context).pop()
          )
        ],
        contentPadding: EdgeInsets.all(10),
      );
    });
  }
}