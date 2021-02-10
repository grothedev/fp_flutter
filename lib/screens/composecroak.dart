/*
Frog Pond mobile application
Copyright (C) 2019  Thomas Grothe

This file is part of FrogPond.

FrogPond is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

FrogPond is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Frog Pond.  If not, see <https://www.gnu.org/licenses/>.
*/

import 'package:FrogPond/controllers/croakcontroller.dart';
import 'package:FrogPond/controllers/tagcontroller.dart';
import 'package:FrogPond/models/tagstore.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:provider/provider.dart';
import 'package:universal_io/io.dart';

//import 'package:file_picker/file_picker.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:toast/toast.dart';
//import 'sugtags.dart';
import '../state_container.dart';
import '../util.dart' as util;
import '../consts.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/localtags.dart';




//for making a root croak (no parent)
class ComposeScreenState extends State<ComposeScreen> with AutomaticKeepAliveClientMixin<ComposeScreen>{

  final fk = GlobalKey<FormState>();// form key
  final croakText = TextEditingController();
  final tagsText = TextEditingController();
  List<String> tags = [];
  bool anon = true;
  File file;
  SharedPreferences prefs; 
  StateContainerState store;
  LocalTagsStore composeTags;
  
  EdgeInsets formPadding = EdgeInsets.all(6.0);
  EdgeInsets formElemMargin = EdgeInsets.all(8.0);

  TagController tagCtrlr;
  CroakController croakCtrlr;

  void initState(){
    super.initState();
    SharedPreferences.getInstance().then((p){
      prefs = p;
    });
    composeTags = new LocalTagsStore();
  }

  @override
  Widget build(BuildContext context){
    super.build(context);
    tagCtrlr = Provider.of<TagController>(context);
    croakCtrlr = Provider.of<CroakController>(context);
    if (composeTags == null || composeTags.tags.isEmpty){// || composeTags.tags.length != store.state.query.localTags.tags.length){
      print('compose screen making composetagstore copy of query tags');
      setState(() {
        composeTags = new LocalTagsStore(tags: tagCtrlr.tagStore.getLabels()); //copying from query tags  
      });
    }
    print(composeTags.getLabels().toString());

    /* TODO test this (disabled button when croaking)
    if (store.state.croaking){
      //originally i had a more dynamic implementation, where screens could still be switched between while uploading, but i was having some issues dealing with the widget tree stuff.
      //so i will leave it like this for now. eventually i should implement the original idea, because that would useful for large files
        return SimpleDialog(
          contentPadding: EdgeInsets.all(8),
          children: <Widget>[
            Text('Croaking...'),
          ],elevation: 3,
        );
    }
    */
    return Scaffold(
      //appBar: ScreenTitle('Croak with your fellow tadpoles'),
      appBar: AppBar(
        title: Text('Croak'),
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
                    Container(
                      padding: formPadding,
                      margin: formElemMargin,
                      child: TextFormField( //CROAK INPUT
                        controller: croakText,
                        validator: (value){
                          if (value.isEmpty) return 'Enter some text';
                        },
                        style: Theme.of(context).textTheme.bodyText1,
                        decoration: InputDecoration(
                          icon: Icon(Icons.message),
                          labelText: 'Post'
                        ),
                        maxLines: 8,
                        minLines: 3, 
                      ),
                    ),
                    Row( 
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: formPadding,
                          margin: formElemMargin,
                          child: TextFormField( //TAGS INPUT
                            controller: tagsText,
                            decoration: InputDecoration(
                              icon: Icon(Icons.category),
                              labelText: 'Tags',
                              //helperText: 'Seperated by Spaces'
                            ),
                            style: Theme.of(context).textTheme.bodyText2,
                            maxLines: 1,
                            minLines: 1,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: .65 * MediaQuery.of(context).size.width,
                            maxHeight: MediaQuery.of(context).size.height
                          ),
                        ),
                        RaisedButton(
                          child: Icon(MdiIcons.plus, semanticLabel: 'Add Tag', size: 18),
                          onPressed: (){
                            setState(() {
                              if (composeTags.getActiveTagsLabels().length > 14){
                                Toast.show('That is enough tags', context);
                              } else if (tagsText.text.length > 0 || tagsText.text.length < 128){
                                setState((){
                                  composeTags.add(tagsText.text, true);
                                });
                              } else {
                                Toast.show('Tag does not meet length requirement', context);
                              }
                            });
                            tagsText.clear();
                          },
                        ),
                      
                      ]
                    ),
                    Container(
                      alignment: Alignment.center,
                      padding: formPadding,
                      margin: formElemMargin,
                      child: LocalTags(composeTags, selectTagChip),
                      decoration: BoxDecoration(
                        //border: Border.all(color: Colors.black, width: 1, style: BorderStyle.solid)
                        border: Border(
                          bottom: BorderSide(color: Theme.of(context).dividerColor),
                          top: BorderSide(color: Theme.of(context).dividerColor)
                        ),
                      ),
                    ),
                    
                    Container(
                      padding: formPadding,
                      margin: formElemMargin,
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0x66222222), width: 1, style: BorderStyle.solid)
                        //border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RaisedButton(
                            onPressed: () => { 
                              /*FilePicker.platform.pickFiles().then((files){
                                if (files.isSinglePick){
                                  PlatformFile f = files.files[0];
                                  if (f.size > MAX_FILESIZE){
                                    setState((){
                                      f = null;
                                      Toast.show('File too big ( >128MB )', context, duration: 4);
                                    });
                                  }
                                  setState(() {
                                    file = new File(f.path);
                                  });
                                } else {

                                }
                              })*/
                              FilesystemPicker.open(
                                title: "Select File",
                                context: context,
                                fsType: FilesystemType.file,
                                rootDirectory: Directory('/sdcard')
                              ).then((String path){
                                print(path);
                              })
                              
                            },
                            child: Text('Attach File', style: Theme.of(context).textTheme.caption),
                            padding: EdgeInsets.all(4),
                          ),
                          Container(
                            padding: EdgeInsets.only(left: 6),
                            child: file == null ? Text('no file') 
                                      : Container(
                                          constraints: BoxConstraints(maxWidth: .5 * MediaQuery.of(context).size.width ),
                                          child: Text(file.toString(), style: Theme.of(context).textTheme.subtitle1, overflow: TextOverflow.ellipsis),
                                          
                                      ),
                                      //constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .6),
                            ),
                          IconButton(
                            icon: Icon(Icons.cancel),
                            onPressed: ()=>setState((){
                              file = null;
                            }),
                            color: Color(0xCC550005)
                          )
                        ],
                        
                      ),
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
                        child: IgnorePointer(
                          ignoring: croakCtrlr.state.croaking,

                          child: RaisedButton(
                            
                            onPressed: (){
                              if (composeTags.getActiveTagsLabels().isEmpty){
                                Scaffold.of(context).showSnackBar(SnackBar(content: Text('Croak needs tags')));
                                return;
                              }
                              if (fk.currentState.validate()){
                                
                                Scaffold.of(context).showSnackBar(SnackBar(content: Text('Croaking...')));
                                croakCtrlr.state.croaking = true;

                                tags.addAll(tagsText.text.split(' ')); // i have no idea why this would generate duplicate tags with no duplicate input
                                tags.removeWhere((t) => t==''); //for some reason there are empty strings ending up in the list
                                
                                print('croakin with tags: ' + tags.toString());
                                util.submitCroak(croakText.text, composeTags.getActiveTagsLabels(), true, store.state.lat, store.state.lon, file).then((r){
                                  if (r != null){
                                    if (r.containsKey('error')){
                                      print(r.toString());
                                      return;
                                    }
                                    Scaffold.of(context).removeCurrentSnackBar();
                                    Scaffold.of(context).showSnackBar(SnackBar(content: Text('Success')));
                                    setState((){
                                      croakText.text = '';
                                      tagsText.text = '';
                                      file = null;
                                    });
                                    //TabBarView b = context.ancestorWidgetOfExactType(TabBarView);
                                    //b.controller.animateTo(b.controller.previousIndex);
                                  } else {
                                    Scaffold.of(context).removeCurrentSnackBar();
                                    Scaffold.of(context).showSnackBar(SnackBar(content: Text('Failed to Croak')));
                                  }
                                  croakCtrlr.submitCroak(r);
                                }).catchError((e){
                                  print('compose croak error: ' + e.toString());
                                  croakCtrlr.state.croaking = false;
                                  Scaffold.of(context).removeCurrentSnackBar();
                                  Scaffold.of(context).showSnackBar(SnackBar(content: Text('Failed to Croak'),));
                                });
                              }
                            },
                            child: Text('Croak')
                          ),
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

  @override
  bool get wantKeepAlive => true;
  
  void selectTagChip(String tag, bool sel){
    if (sel && composeTags.getActiveTagsLabels().length > 14){
      Toast.show('That is enough tags', context);
      return;
    }
    composeTags.use(tag, sel);
  }
}

//for making a croak
class ComposeScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return ComposeScreenState();
  }
}