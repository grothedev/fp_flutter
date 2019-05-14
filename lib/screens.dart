import 'dart:io';

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
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'consts.dart';
import 'models.dart';
import 'db.dart' as db;
import 'api.dart' as api;
import 'util.dart' as util;

//this screen should show a UI to set feed filter, user account pref, notifications
class HomeScreen extends StatelessWidget {

  TextEditingController dbgTC;
  final fk = GlobalKey<FormState>();
  TextEditingController tagsText = TextEditingController();

  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to FrogPond')
      ),
      body: Container(
        child: Form(
          key: fk,
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextFormField( //TAGS INPUT
                      controller: tagsText,
                      decoration: InputDecoration(
                        icon: Icon(Icons.category),
                        labelText: 'Tags'
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
              ],
            )
          ),
        ),
      )
    );
    
  }
}


class FeedScreen extends StatefulWidget {

  const FeedScreen() : super();

  @override
  FeedState createState() {
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
    print("initing feed state");
    SharedPreferences.getInstance().then((p){
      print('got shared pref');
      prefs = p;
      lastUpdated = prefs.getInt('last_croaks_get');
      
      if (true || lastUpdated == null || DateTime.now().millisecondsSinceEpoch - lastUpdated > CROAKS_GET_TIMEOUT){
        initLocation().then((l){
          print('got loc');
          if (l != null){
            prefs.setDouble('lat', l.longitude);
            prefs.setDouble('lon', l.latitude);
          } else {
            print('null loc');
          }
          
          print('getting croaks');
          util.getCroaks(l).then((r){
            print('croaks gotten');
            r.sort((a, b){
              return DateTime.parse(b['created_at']).millisecondsSinceEpoch - DateTime.parse(a['created_at']).millisecondsSinceEpoch;
            });
            populateListView(r);
          });
        }).timeout(new Duration(seconds: 12), onTimeout: (){
          print('failed to get location');
          print('getting croaks');
          util.getCroaks(null).then((r){
            print('croaks gotten');
            r.sort((a, b){
              return DateTime.parse(b['created_at']).millisecondsSinceEpoch - DateTime.parse(a['created_at']).millisecondsSinceEpoch;
            });
            populateListView(r);
          });
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
          child: Column(
            children: [
              Text("Finding Location..."),
              CircularProgressIndicator(
                  value: null,
                  semanticsLabel: 'Retreiving Croaks...',
                  semanticsValue: 'Retreiving Croaks...',
              ),
            ]
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
            onPressed: () => util.getCroaks(location),

          ),
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: () => sortOptions()
          )
        ],
      ),
      body: Container(
        child: CroakFeed(context: context, pid: 0, croaksJSON: croaksJSON)
      ),

      /* 
      floatingActionButton: FloatingActionButton(
            child: new Icon(Icons.add),
            onPressed: makeCroak,
          ),
      */
      );
        
  }

  

  void populateListView(List crks){
    print('setting state');
    setState(() {
        //res is a list decoded from json 
        loading = false;
        croaksJSON = crks;
        for (int i = 0; i < croaksJSON.length; i++){
          var cj = croaksJSON[i];
          for (int j = 0; j < cj['tags'].length; j++){
            print(cj['tags'][j]['label']);
          }
        }
    });
    db.saveCroaks(croaksJSON);
    prefs.setInt('last_croaks_get', DateTime.now().millisecondsSinceEpoch);
    
  }

  void sortOptions(){

  }

  Future<LocationData> initLocation() async{
    print('initing loc');

    Location().serviceEnabled().then((s){
      if (!s) Location().requestService().then((r){
        if (!r) {
          print('service denied');
          return null;
        }
      });
    });
   
    Location().hasPermission().then((p){
      if (!p) Location().requestPermission().then((r){
        if (!r) {
          print('permission denied');
          return null;
        }
      });
    });

    try{
      print ('getting loc');
      return Location().getLocation(); //hanging here on windows emulation
      
    } on PlatformException catch (e){
      if (e.code == 'PERMISSION_DENIED'){
        print('permission denied');
      }
      print(e.code);
      return null;
    }
      
  }
}

class CroakFeedState extends State<CroakFeed>{
  int pid;
  List croaksJSON; //json array
  BuildContext context;
  List<bool> favs;

  CroakFeedState({this.context, this.pid, this.croaksJSON}){
    favs = new List<bool>();
  }

  @override
  Widget build(BuildContext context) {
    if (croaksJSON == null){
      return new Container(
        child: Text('no croaks'),
      );
    }
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

      //DateTime.parse(croaksJSON['timestamp']).millisecondsSinceEpoch;
    favs.add(false);

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
            RaisedButton( key: new Key(i.toString()), onPressed: (){fav(i);},  child: favs[i] ? Icon(Icons.favorite) : Icon(Icons.favorite_border) ), 
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

  //toggles "favorite" or normal for a croak  
  void fav(int id){
    setState((){
      favs[id] = !favs[id];
    });
  }
}

class CroakFeed extends StatefulWidget{
  final BuildContext context;
  final int pid;
  final List croaksJSON;

  CroakFeed({this.context, this.pid, this.croaksJSON});

  @override
  State<StatefulWidget> createState() {
    return CroakFeedState(context: context, pid: pid, croaksJSON: croaksJSON);
  }
  
}

class ComposeScreenState extends State<ComposeScreen>{

  final fk = GlobalKey<FormState>();// form key
  final croakText = TextEditingController();
  final tagsText = TextEditingController();
  bool anon = true;
  String file;
  SharedPreferences prefs; 

  void initState(){
    SharedPreferences.getInstance().then((p){
      prefs = p;
    });
  }

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
                    TextFormField( //CROAK INPUT
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
                    TextFormField( //TAGS INPUT
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
                    SuggestedTags(),
                    Row(
                      children: [
                        RaisedButton(
                          onPressed: getFile,
                          child: Text('Attach File'),

                        ),
                        Container(
                          padding: EdgeInsets.only(left: 15),
                          child: file == null ? Text('no file') : Text(file.toString())
                        ),
                      ]
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
                    
                    Padding( //CROAK SUBMIT
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(
                        child: RaisedButton(
                        
                          onPressed: (){
                            if (fk.currentState.validate()){
                              Scaffold.of(context).showSnackBar(SnackBar(content: Text('Croaking...')));
                              util.submitCroak(croakText.text, tagsText.text, true, prefs.getDouble('lat'), prefs.getDouble('lon')).then((r){
                                if (r){
                                  Scaffold.of(context).removeCurrentSnackBar();
                                  Scaffold.of(context).showSnackBar(SnackBar(content: Text('Success')));
                                  TabBarView b = context.ancestorWidgetOfExactType(TabBarView);
                                  b.controller.animateTo(b.controller.previousIndex);
                                } else {
                                  Scaffold.of(context).removeCurrentSnackBar();
                                  Scaffold.of(context).showSnackBar(SnackBar(content: Text('Croak failed to post')));

                                }
                              });
                            }
                          },
                          child: Text('Croak')
                        ),
                      )
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

  Future getFile() async{ //currently supports one file; will provide multiple files in future if necessary
    var f = await FilePicker.getFilePath(type: FileType.ANY);
    setState((){
      file = f;
    });
  }
  
}

//for making a croak
class ComposeScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return ComposeScreenState();
  }
}

class SuggestedTags extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Wrap( 
        
        children:[
          ChoiceChip(
            label: Text('Test_tag_sug'),
            selected: false
          )
        ]
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
      appBar: AppBar(
        title: Text(c['created_at']),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: (){
              Clipboard.setData(ClipboardData(text: api.api_url+'croaks/'+c['id'].toString()));
            },
          )
        ]
      ),
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
              child: CroakFeed(
                context: context,
                pid: c['id'],
                croaksJSON: null, //TODO
              ) //getCroaks(parentId) . figure out how to support threaded system
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

  void copyURL(){

  }
  
}