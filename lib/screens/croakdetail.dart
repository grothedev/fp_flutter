import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fp/state_container.dart';
import 'package:toast/toast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../util.dart' as util;
import '../api.dart' as api;
import '../db.dart' as db;
import 'helpers.dart';


final String ro_url_pre = 'http://' + api.host + '/c/'; //prefix of url for fancy read-only webview

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
        title: Text(c['created_at']),
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
            }
          )
        ]
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Title(
                      child: Text(' / | \\ ', 
                              //style: TextStyle(decoration: TextDecoration.underline)
                             ),
                      color: Colors.black
                    ),
                    Container( //croak content  
                      child: Text(c['content'], style: Theme.of(context).textTheme.body1),
                      alignment: Alignment.topLeft,
                      decoration: BoxDecoration(
                        
                        border: Border(
                          bottom: BorderSide(width: 1.0, color: Theme.of(context).dividerColor),
                          top: BorderSide.none,
                          right: BorderSide.none,
                          left: BorderSide.none,
                          
                        ),
                      ),
                      padding: EdgeInsets.only(left: 14.0, bottom: 6),
                      margin: EdgeInsets.only(bottom: 8.0),
                    ),
                    Container(
                      alignment: Alignment.topLeft,
                      child: Text(tags.join(', '), style: Theme.of(context).textTheme.body2),
                      margin: EdgeInsets.only(bottom: 8.0),
                      padding: EdgeInsets.only(left: 22.0, bottom: 6),
                    ),
                    
                        c['files'] != null && c['files'].length > 0 ? 
                        Container(
                          height: MediaQuery.of(context).size.height * .3,
                          child: fileView(c['files'])
                         ) : Center(),
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Theme.of(context).dividerColor),
                            )
                          ),
                          margin: EdgeInsets.only(bottom: 12.0),
                        ),
                        Expanded(
                          key: GlobalKey(),
                          flex: 1,
                          child: replies != null && replies.length > 0 ? 
                            CroakFeed(
                              replies
                            ) :
                            Text('No Replies')
                        ),
                      ],
              ),
            ),
            /*Container(
              padding: EdgeInsets.all(8.0),
              alignment: Alignment(0, 1),
              child: Form(
                  key: fk,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: contentController,
                        validator: (value){
                            if (value.isEmpty) return 'Enter some text';
                        },
                        decoration: InputDecoration(
                          icon: Icon(Icons.message),
                          labelText: 'Reply',      
                        ),
                        maxLines: 3,
                        minLines: 1,
                        autofocus: false,
                        autovalidate: false,
                        
                      ),
                        //force anon for phase 1
                        /*
                        CheckboxListTile(
                          value: this.anon,
                          title: Text('anon'),
                          onChanged: (v){
                            anon = !anon;
                          },

                        ),
                        */
                        RaisedButton(
                          onPressed: (){
                            if (fk.currentState.validate()){
                              //Scaffold.of(context).showSnackBar(SnackBar(content: Text('Replying...')));
                              print('attempting to reply: ' + c['tags'].toString());
                              util.submitReply(c['id'], contentController.text, c['tags'], true).then((success){
                                if (success){
                                  Toast.show("Ribbit", context);
                                  contentController.clear();
                                  getReplies();
                                }
                              }); //TODO add functionality to add additional tags?
                            }
                          },
                          child: Text("Reply"),
                          
                        )
                    ]
                  ),
                ),
            )*/
          ],
        ),
        padding: EdgeInsets.all(12.0),
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
      return Center(
        child: GestureDetector(
          onTap: (){
            launch('http://' + api.host + '/f/' + fn);
          },
          child: Image.network(
            'http://' + api.host + '/f/' + fn,
            fit: BoxFit.fitHeight,
             
          ),
        )
      );
    } else return Center(
      child: RaisedButton(
        child: Text(c['files'][0]['filename'].toString()),
        onPressed: (){
          launch('http://' + api.host + '/f/' + c['files'][0]['filename']);
        },
      ),
    
    );
  }
}

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