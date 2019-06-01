import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'sugtags.dart';
import '../util.dart' as util;
import 'package:location/location.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';




//for making a root croak (no parent)
class ComposeScreenState extends State<ComposeScreen> with AutomaticKeepAliveClientMixin<ComposeScreen>{

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
      body: SingleChildScrollView(
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
                    //SuggestedTags(),
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
                    
                    //for phase 1, force anon
                    /*
                    Row(
                      children: <Widget>[
                        Text('anon'),
                        Checkbox(
                          onChanged: (val){
                            setState((){
                              anon = val;
                            });
                          },
                          value: this.anon,
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                        ),

                      ],
                    ),
                    */  
                    
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

  @override
  bool get wantKeepAlive => true;
  
}

//for making a croak
class ComposeScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return ComposeScreenState();
  }
}