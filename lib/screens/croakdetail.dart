import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toast/toast.dart';

import '../util.dart' as util;
import '../api.dart' as api;
import '../db.dart' as db;
import 'helpers.dart';


class CroakDetailScreen extends StatelessWidget{

  Map c;

  //this stuff is now in the compose croak dialog
  //final replyController = TextEditingController();
  //final fk = GlobalKey<FormState>();// form key
  //bool anon = true;

  CroakDetailScreen(Map c){
    this.c = c;
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
                CroakFeed(
                  context: context,
                  pid: c['id'],
                  croaksJSON: null, //TODO
                ),
              ], //comments
              
               //getCroaks(parentId) . figure out how to support threaded system
            ),
            Container(
              padding: EdgeInsets.all(8.0),
              alignment: Alignment(0, 1),
            )
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

  void copyURL(){

  }
  
}