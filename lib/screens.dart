import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class HomeScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to FrogPond')
      ),
      body: Container()
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
  
  String api_url = 'http://grothe.ddns.net:8090/api/';
  List croaks;

  //NOTE: croaks are currently redownloaded upon every time going back to screen
  @override
  void initState(){
    super.initState();
    getCroaks();
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
           
        floatingActionButton: FloatingActionButton(
              child: new Icon(Icons.add),
              onPressed: makeCroak,
            ),
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
      //tags.add('asdf');
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
        onTap: (){}, //TODO croak screen

      );
  }
  
  //presents UI elems to allow user to compose a new croak
  void makeCroak(){
    //TODO figure out best way to implement this
  }


  //TODO come up with way to properly deal with caching
  //https://flutter.dev/docs/cookbook/persistence/sqlite
  Future<String> getCroaks() async {
    var res = await http.get(api_url+'croaks');
    print(res.body);

    setState((){
      croaks = json.decode(res.body);
    });

    saveCroaks(croaks);

  }

  void saveCroaks(croaks) async{
    var c = [];

    final Future<Database> dbFuture = openDatabase(
      join(await getDatabasesPath(), 'fp.db'),
      onCreate: (db, v){
        db.execute('CREATE TABLE croaks(id INTEGER PRIMARY KEY, timestamp DATE, content TEXT, score INTEGER, tags TEXT)');
      },
      version: 1
    );
    final Database db = await dbFuture;

    for (int i = 0; i < croaks.length; i++){
      c.add(new Croak({croaks[i]['id'], croaks[i]['content'], croaks[i]['timestamp'], croaks[i]['tags'], croaks[i]['score']}));
      db.insert('croaks', c[i].toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
  }



}