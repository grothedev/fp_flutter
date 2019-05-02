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
  
  List croaks; //this is the same json data structure that is returned by api call 
  int lastUpdated;
  LocationData location;
  SharedPreferences prefs;

  @override
  void initState(){
    super.initState();

    SharedPreferences.getInstance().then((p){
      prefs = p;
      lastUpdated = prefs.getInt('last_croaks_get');
      //TODO remove dbg true
      if (true || lastUpdated == null || DateTime.now().millisecondsSinceEpoch - lastUpdated > CROAKS_GET_TIMEOUT){
        initLocation().then((l){

          double x, y;
          if (l != null){
            x = l.longitude;
            y = l.latitude;
            prefs.setDouble('lat', y);
            prefs.setDouble('lon', x);
          } else {
            x = y = null;
          }

          api.getCroaks(x, y).then((res){
            setState(() {
              //res is a list decoded from json 
              croaks = res;
            });
            print('passing to db: ' + croaks.toString());
            db.saveCroaks(croaks);
            p.setInt('last_croaks_get', DateTime.now().millisecondsSinceEpoch);
          });

        });
      } else {
        print('loading croaks from sqlite');
        db.loadCroaks().then((crks){
          print('croaks loaded: ' + crks.toString());
          setState(() {
            croaks = crks.toList();
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Tha Pond')
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
      itemCount: croaks == null ? 0 : croaks.length,
      itemBuilder: (context, i) {
        return new Container(
          child: feedItem(i),
        );
      }
    );
  }

  Widget feedItem(i){
    var tags = [];
    
    for (int j = 0; j < tags.length; j++){
      tags.add(croaks[i]['tags'][j]['label']);
    }

    return new ListTile(
        title: Text(croaks[i]['content']),
        trailing: Icon(Icons.favorite),
        subtitle: Row(
          children: <Widget>[
            Text(croaks[i]['created_at']),
            Text(tags.toString())
          ]
        ),
        onTap: (){
          Navigator.pushNamed(this.context, 'croakdetail');
        }, //TODO croak screen

      );
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
                  ),
                  Switch(
                    value: true,
                    onChanged: (val){
                      anon = val;
                    },
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
            ),
          ]
        )
      )
    );
  }

  void submitCroak(String croak, String tags, anon){
    
    Croak c = new Croak(id: anon ? -1 : 0 , content: croak, timestamp: new DateTime.now().toString() , tags: tags, score: 0);

    api.postCroak(c.toMap());
  }
}

class CroakDetailScreen extends StatelessWidget{

  //TODO pass in data, probably will need to be stateful widget
  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      appBar: AppBar(title: Text('Detail of Croak c')),
      body: Container(),
      bottomSheet: Form(),
    );
  }
  
}