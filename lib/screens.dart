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
  var lastUpdated;

  //NOTE: croaks are currently redownloaded upon every time going back to screen
  @override
  void initState(){
    super.initState();
    print(lastUpdated);
    lastUpdated = DateTime.now();
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


  //TODO is sqlite caching as clean as it can be?
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
            //Text('Text'),
            //EditableText(),

          ]
        )
      )
    );
  }

  void submitCroak(String croak, String tags, anon){
    Croak c = new Croak({0-anon, croak, new DateTime.now().toString() , tags, 0});
    
  }

  /*
  Future<String> postCroak() async {
    var res = await http.post(api_url+'croaks', ); //TODO 
    print(res.body);

  }
  */
}

