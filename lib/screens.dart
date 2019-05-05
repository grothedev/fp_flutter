import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';
import 'db.dart' as db;
import 'api.dart' as api;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'consts.dart';


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
            croaksJSON = crks.toList();
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
        trailing: Icon(Icons.favorite),
        subtitle: Row(
          children: <Widget>[
            Text(croaksJSON[i]['created_at']),
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

    //TODO dbging, remove
    showDialog(
      builder: (BuildContext context){
      return AlertDialog(
        title: Text('location'),
        content: Text(location.toString()),
      );
      }, context: this.context
    );
      
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
                          value: true,
                          onChanged: (val){
                            anon = val;
                          },
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
                            submitCroak(croakText.text, tagsText.text, anon);
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

  void submitCroak(String croak, String tags, anon){
    Croak c = new Croak(id: anon ? -1 : 0 , content: croak, timestamp: new DateTime.now().toString() , score: 0);
    api.postCroak(c.toMap());
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

  //TODO pass in data, probably will need to be stateful widget
  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      appBar: AppBar(title: Text(c['created_at'])),
      body: Container(
        child: Text(c['content']),
        padding: EdgeInsets.all(12.0),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.all(8.0),
        child: Form(
          key: fk,
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  TextFormField(
                    controller: replyController,
                    validator: (value){
                        if (value.isEmpty) return 'Enter some text';
                      },
                      decoration: InputDecoration(
                        icon: Icon(Icons.message),
                        labelText: 'Reply'
                      ),
                  ),
                  FlatButton(
                    onPressed: (){
                      if (fk.currentState.validate()){
                        Scaffold.of(context).showSnackBar(SnackBar(content: Text('Replying...')));
                        submitReply(c);
                      }
                    },
                    child: Text("Reply"),

                  )
                ]
              ),
              Row(
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
      
    );
  }

  void submitReply(Map parent){
    Croak c = new Croak(id: anon ? -1 : 0 , content: replyController.text, timestamp: new DateTime.now().toString() , score: 0);
    c.pid = parent['id'];
    api.postCroak(c.toMap());
  }
  
}