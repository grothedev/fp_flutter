import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fp/state_container.dart';
import 'package:intl/intl.dart';
import 'package:toast/toast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../util.dart' as util;
import '../api.dart' as api;
import '../db.dart' as db;
import 'helpers.dart';


final String ro_url_pre = 'http://' + api.host + '/c/'; //prefix of url for fancy read-only webview


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

  //this stuff is now in the compose croak dialog
  //final replyController = TextEditingController();
  //final fk = GlobalKey<FormState>();// form key
  //bool anon = true;

  CroakDetailState(Map c){
    this.c = c;
  }

  @override
  void initState(){
    super.initState(); 
    getReplies(); 
  }


  @override
  Widget build(BuildContext context) {
    print(c['files'].toString());
    List tags = [];
    for (int j = 0; j < c['tags'].length; j++){
      tags.add(c['tags'][j]['label']);
    }

    if (StateContainer.of(context).state.updateReplies) getReplies();

    String croakURL = ro_url_pre+c['id'].toString();
    return Scaffold( 
        appBar: AppBar(
          title: Text(c['timestampStr']),
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
            )
          ]
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
                  child: Text(c['content'])
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
              margin: EdgeInsets.only(bottom: 12.0),
            ),

            Expanded( //REPLIES
              key: GlobalKey(),
              flex: 1,
              child: replies != null && replies.length > 0 ? 
                CroakFeed(
                  replies, getReplies, pip: c['ip']
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
      setState((){
        for (int i = 0; i < r.length; i++){
          DateTime dt = DateFormat('yyyy-mm-d HH:mm').parse(r[i]['created_at']).toLocal();
          r[i]['timestampStr'] = dt.year.toString() + '/' + dt.month.toString() + '/' + dt.day.toString() + ' - ' + dt.hour.toString() + ':' + dt.minute.toString();
        }
        this.replies = r;
      });
      StateContainer.of(context).gotReplies();
    });
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
}