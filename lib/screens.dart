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
  
  List croaks;
  var lastUpdated;
  var location;

  //NOTE: croaks are currently redownloaded upon every time going back to screen
  @override
  void initState(){
    super.initState();
    print(lastUpdated);
    lastUpdated = DateTime.now(); //TODO deal with caching and sqlite stuff properly

    initLocation();

    api.getCroaks().then((res){
      setState(() {
        croaks = res;
      });
      db.saveCroaks(croaks);
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
    for (int j = 0; j < croaks[i]['tags'].length; j++){
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

  void initLocation() async{

    Location().serviceEnabled().then((s){
      if (!s) Location().requestService().then((r){
        initLocation();
        return;
      });
    });
   
    Location().hasPermission().then((p){
      if (!p) Location().requestPermission().then((r){
        initLocation();
        return;
      });
    });

    var loc = new Location();
    try{
      await loc.getLocation().then((l){
        location = l;
      });
    } on PlatformException catch (e){
      if (e.code == 'PERMISSION_DENIED'){
        print('permission denied');
      }
      location = null;
    }

    print(location.toString());
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