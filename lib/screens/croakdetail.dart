import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toast/toast.dart';

import '../util.dart' as util;
import '../api.dart' as api;
import '../db.dart' as db;
import 'helpers.dart';


class CroakDetailState extends State<CroakDetailScreen>{

  Map c;
  final contentController = TextEditingController();
  static final fk = GlobalKey<FormState>();// form key
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

    return Scaffold( 
      appBar: AppBar(
        title: Text(c['created_at']),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: (){
              Clipboard.setData(ClipboardData(text: api.api_url+'croaks/'+c['id'].toString()));
              Toast.show('URL copied to clipboard', context);
            },
          )
        ]
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Container( //croak content
                child:  Text(c['content']), 
                padding: EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(
                  
                    border: Border(
                      bottom: BorderSide(width: 1.0, color: Colors.black),
                      top: BorderSide.none,
                      right: BorderSide.none,
                      left: BorderSide.none,
                    ),
                  ),
                ),
            ),
            
            Column(
              children: <Widget>[
                Title(
                  
                  child: Text('Comments'),
                  color: Colors.black,
                ),
                replies == null ?
                CircularProgressIndicator(
                      value: null,
                      semanticsLabel: 'Retreiving Comments...',
                      semanticsValue: 'Retreiving Comments...',
                ) : 
                CroakFeed(
                  context: context,
                  pid: c['id'],
                  croaksJSON: replies, 
                ),
              ], //comments
              
               //getCroaks(parentId) . figure out how to support threaded system
            ),
            Container(
              padding: EdgeInsets.all(8.0),
              alignment: Alignment(0, 1),
              child: Form(
                  key: fk,
                  child: Column(
                    //direction: Axis.vertical,
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
                        autofocus: true,
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
                                }
                              }); //TODO add functionality to add additional tags?
                            }
                          },
                          child: Text("Reply"),

                        )
                    ]
                  ),
                ),
            )
          ],
        ),
        padding: EdgeInsets.all(12.0),
      ),
      //bottomSheet: Text('bottomsheet test'),
      /*floatingActionButton: FloatingActionButton(
        onPressed: (){
          showDialog(context: context, builder: (context) {
            return ComposeCroakDialog(c);
          });
        },
        child: Icon(Icons.reply),

      ),*/
    );
  }

  void getReplies(){
    util.getReplies(c['id']).then((r){
      setState((){
        this.replies = r;
      });
    });
  }

  void copyURL(){

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