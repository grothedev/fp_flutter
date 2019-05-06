import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'consts.dart';

import 'models.dart';
import 'db.dart' as db;
import 'api.dart' as api;
import 'util.dart' as util;

//this screen should show a UI to set feed filter, user account pref, notifications
class HomeScreen extends StatelessWidget {

  TextEditingController dbgTC;

  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to FrogPond')
      ),
      body: Container(
        child: Text(
          'location data',
          key: Key('dbgT'),
          
          ),
        ),
      );
    
  }
}


class FeedScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return new FeedState();
  }
}

class FeedState extends State<FeedScreen>{
  
  List croaksJSON; //this is the same json data structure that is returned by api call 
  List<Croak> croaks;
  bool loading = true;
  int lastUpdated;
  LocationData location;
  SharedPreferences prefs;

  @override
  void initState(){
    super.initState();
    SharedPreferences.getInstance().then((p){
      prefs = p;
      lastUpdated = prefs.getInt('last_croaks_get');
      
      if (true || lastUpdated == null || DateTime.now().millisecondsSinceEpoch - lastUpdated > CROAKS_GET_TIMEOUT){
        initLocation().then((l){

          getCroaks(l);

        });
      } else {
        print('loading croaks from sqlite');
        db.loadCroaks().then((crks){
          print('croaks loaded: ' + crks.toString());
          setState(() {
            List tmp = croaks.toList();
            for (int i = 0; i < tmp.length; i++){
              if (tmp[i]['p_id'] != 0){ //make sure it's not a comment croak
                tmp.removeAt(i);
                i--;
              }
            }
            croaksJSON = tmp;

            loading = false;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading){
      return Center(
        child: Container(
          width: 120, 
          height: 120,
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(
              value: null,
              semanticsLabel: 'Retreiving Croaks...',
              semanticsValue: 'Retreiving Croaks...',
          )
        )
      );
    }
      return Scaffold(
        appBar: AppBar(
          title: Text('Tha Pond'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () => getCroaks(location),

            ),
          ],
        ),
        body: Container(
          child: feedBuilder()
        ),

        /* 
        floatingActionButton: FloatingActionButton(
              child: new Icon(Icons.add),
              onPressed: makeCroak,
            ),
        */
        );
        
  }

  Widget feedBuilder(){
    return new ListView.builder(
      itemCount: croaksJSON == null ? 0 : croaksJSON.length,
      itemBuilder: (context, i) {
        return new Container(
          child: feedItem(i),
        );
      },
      shrinkWrap: true,
    );
  }

  Widget feedItem(i){
    List tags = [];
    
    for (int j = 0; j < croaksJSON[i]['tags'].length; j++){
      tags.add(croaksJSON[i]['tags'][j]['label']);
    }

    return new ListTile(
        title: RichText(
          text: TextSpan( 
            text: croaksJSON[i]['content'],
            style: TextStyle(color: Colors.black),
          ),
          maxLines: 2,
          overflow: TextOverflow.fade
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite),
            Text(croaksJSON[i]['score'].toString(), textAlign: TextAlign.center,)
          ]
        ),
        subtitle: Row(
          children: <Widget>[
            Text(croaksJSON[i]['created_at']), //TODO add # replies?
            Spacer(
              flex: 2
            ),
            Text(tags.join(', '))
          ]
        ),
        onTap: (){
          Navigator.push(this.context, MaterialPageRoute(
            builder: (context) => CroakDetailScreen(croaksJSON[i])
          ));
        },
        
      );

      
  }

  void getCroaks(loc){
    
    double x, y;
    if (loc != null){
      x = loc.longitude;
      y = loc.latitude;
      prefs.setDouble('lat', y);
      prefs.setDouble('lon', x);
    } else {
      x = y = null;
    }

    api.getCroaks(x, y).then((res){
      setState(() {
        //res is a list decoded from json 
        loading = false;
        croaksJSON = res;
        for (int i = 0; i < croaksJSON.length; i++){
          var cj = croaksJSON[i];
          //croaks.add(Croak(id: cj['id'], content: cj['content'], timestamp: cj['created_at'], score: cj['score'], lat: cj['y'], lon: cj['x'], type: cj['type']));
          //var tl = json.decode(cj['tags'].toString());
          for (int j = 0; j < cj['tags'].length; j++){
            //cj['tags'][j] = tl[j]['label'];
            print(cj['tags'][j]['label']);
          }
        }
      });
      db.saveCroaks(croaksJSON);
      prefs.setInt('last_croaks_get', DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<LocationData> initLocation() async{

    Location().serviceEnabled().then((s){
      if (!s) Location().requestService().then((r){
        if (!r) return null; //service denied
      });
    });
   
    Location().hasPermission().then((p){
      if (!p) Location().requestPermission().then((r){
        if (!r) return null; //permission denied
      });
    });

    try{
      new Location().getLocation().then((loc){
        return loc;
      });
    } on PlatformException catch (e){
      if (e.code == 'PERMISSION_DENIED'){
        print('permission denied');
      }
      location = null;
      return null;
    }
      
  }
}

//for making a croak
class ComposeScreen extends StatelessWidget {

  final fk = GlobalKey<FormState>();// form key
  final croakText = TextEditingController();
  final tagsText = TextEditingController();
  bool anon = true;

 @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('Croak with your fellow tadpoles')
      ),
      body: Container(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Form(
              key: fk,
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: croakText,
                      validator: (value){
                        if (value.isEmpty) return 'Enter some text';
                      },
                      decoration: InputDecoration(
                        icon: Icon(Icons.message),
                        labelText: 'Post'
                      ),
                      maxLines: 8,
                      minLines: 3, 
                    ),
                    TextFormField(
                      controller: tagsText,
                      validator: (value){
                        if (value.isEmpty) return 'Enter some tags, seperated by spaces';
                      },
                      decoration: InputDecoration(
                        icon: Icon(Icons.category),
                        labelText: 'Tags'
                      ),
                      maxLines: 3,
                      minLines: 2,
                      
                    ),
                    Row(
                      children: <Widget>[
                        Text('anon'),
                        Checkbox(
                          onChanged: (val){
                            anon = val;
                          },
                          value: true,
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                        ),

                      ],
                    ),
                    
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: RaisedButton(
                        onPressed: (){
                          if (fk.currentState.validate()){
                            Scaffold.of(context).showSnackBar(SnackBar(content: Text('Croaking...')));
                            util.submitCroak(croakText.text, tagsText.text, anon).then((r){
                              Scaffold.of(context).showSnackBar(SnackBar(content: Text('Success')));
                            } else {
                              Scaffold.of(context).showSnackBar(SnackBar(content: Text('Croak failed to post')));
                            });
                          }
                        },
                        child: Text('Croak')
                      ),
                    )

                  ],
                )
              )
            ),
          ]
        )
      )
    );
  }
}

class CroakDetailScreen extends StatelessWidget{

  Map c;
  final replyController = TextEditingController();
  final fk = GlobalKey<FormState>();// form key
  bool anon = true;

  CroakDetailScreen(Map c){
    this.c = c;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      appBar: AppBar(title: Text(c['created_at'])),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container( //croak content
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
            Container( //comments
              child: FeedScreen() //getCroaks(parentId) . figure out how to support threaded system
            ),
            Container(
              
              padding: EdgeInsets.all(8.0),
              alignment: Alignment(0, 1),
              child: Form(
                key: fk,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                          controller: replyController,
                          validator: (value){
                              if (value.isEmpty) return 'Enter some text';
                            },
                            decoration: InputDecoration(
                              icon: Icon(Icons.message),
                              labelText: 'Reply'
                            ),
                            
                          ),
                        ),
                        RaisedButton(
                          onPressed: (){
                            if (fk.currentState.validate()){
                              Scaffold.of(context).showSnackBar(SnackBar(content: Text('Replying...')));
                              Croak r = Croak();
                              util.submitReply(c['pid'], replyController.text, c['tags'], true); //TODO add functionality to add additional tags?
                            }
                          },
                          child: Text("Reply"),

                        )
                      ]
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('anon'),
                        Checkbox(
                          value: true,
                          onChanged: (v) => {anon = v},
                        )
                      ]
                    ),
                  ]
                ),
              
              ),
            )
          ],
        ),
        padding: EdgeInsets.all(12.0),
      ),
      
      
    );
  }
  
}