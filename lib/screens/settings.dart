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

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import '../models.dart';
import '../state_container.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:toast/toast.dart';

import '../api.dart' as api;
import '../helpers/localtags.dart';
import '../util.dart' as util;

class SettingsScreenState extends State<SettingsScreen> with AutomaticKeepAliveClientMixin<SettingsScreen>{
  
  TextEditingController dbgTC;
  final fk = GlobalKey<FormState>();
  TextEditingController tagsText = TextEditingController();
  //TextEditingController tagsEText = TextEditingController();
  TextEditingController radText = TextEditingController();
  TextEditingController notifyIntervalTC = TextEditingController();
  bool kwdAll = false;
  List tagsI;
  List tagsE;
  SharedPreferences prefs;
  String locStr;
  StateContainerState store;
  int notifyInterval; //minute interval for background checking of responses 
  double radius;
  double radiusSlider = 30; //used just for the slider UI component
  String motd; //message from the dev, used for important info i want users to see
  bool lefthand = false; //left handed user

  EdgeInsets formPadding = EdgeInsets.all(6.0);
  EdgeInsets formElemMargin = EdgeInsets.all(8.0);

  initState(){

    SharedPreferences.getInstance().then((p){
      this.prefs = p;
      if (!prefs.containsKey('ran_before')){
        Scaffold.of(context).showSnackBar(
          SnackBar(
            content: Text('First time?'), 
            action: SnackBarAction(
                label: 'Tap here to learn',
                onPressed: ()=>launch('http://gooob.bitbucket.io'),

              ),
              duration: Duration(seconds: 8),  
          )
        );
      }
    });

  }

  @override
  Widget build(BuildContext context){
    store = StateContainer.of(context);
    if (store.state.query.radius != null) {
      setState(() {
        radius = store.state.query.radius.toDouble();
        radText.text = radius.toString();
      });
    } 
    if (store.state.notifyCheckInterval != null){
      setState(() {
        notifyInterval = store.state.notifyCheckInterval;
        notifyIntervalTC.text = notifyInterval.toString();
      });
    }
    if (store.state.lat == null || store.state.lon == null){
      store.getLocation();
      locStr = 'Getting Location...';
    
    } else locStr = 'Your Location: ' + store.state.lat.toString() + ', ' + store.state.lon.toString();
    
    if (store.state.query.localTags.tags == null || store.state.query.localTags.tags.isEmpty){
      store.getSuggestedTags();
    }
    lefthand = store.state.lefthand;

    if (motd == null){
      getMOTD();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Frog Pond - Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () => launch('http://' + api.host + ':8090/about'),
            tooltip: 'Help',
          ),
          /*IconButton( //TODO REMOVE debug button for logging things, writing info to files, etc.
            icon: Icon(Icons.bug_report),
            onPressed: () {
              //SharedPreferences.getInstance().then((p) async {
                //util.checkNotifications();
              //});
              store.checkNotifications();
            },
            tooltip: 'DBG'
          )*/
        ]
      ),
      body:  SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Form(
              key: fk,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ' Refine your search query     ',
                        style: Theme.of(context).textTheme.headline2                        
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 6, top: 12, right: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(' Search Radius  ', style: Theme.of(context).textTheme.headline3),
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: .2 * MediaQuery.of(context).size.width
                              ),
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                controller: radText,
                                onChanged: (rad){
                                  radius = double.parse(radText.text);
                                  print('got rad ' + radius.toString());
                                  SharedPreferences.getInstance().then((pref){
                                    pref.setInt('radius', radius.toInt());
                                  });
                                  store.setRadius(radius.toInt());              
                                },
                                decoration: InputDecoration(
                                  hintText: 'Radius',
                                  labelText: 'kilometers',
                                  contentPadding: EdgeInsets.all(0),
                                  isDense: true,
                                ),
                                textAlign: TextAlign.left,
                                style: Theme.of(context).textTheme.subtitle1,

                                maxLines: 1,
                                minLines: 1,
                                expands: false,
                                //initialValue: '0 = infinity',
                              ),
                              //margin: formElemMargin
                            ),
                          ]
                        )
                      ),
                      Container(
                        padding: EdgeInsets.all(8)
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          lefthand ? Container() : Text(' Tags:   ', style: Theme.of(context).textTheme.headline3),
                          Container(
                            child: CheckboxListTile(
                              title: Text('Require all tags'),
                              dense: true,
                              value: store.state.query.tagsIncludeAll,
                              onChanged: (v){
                                store.tagsIncludeAll(v);
                                Toast.show(v ? "Only croaks containing all of these tags will be in your pond" : "Croaks containing any of these tags will be in your pond", context);
                              },
                              activeColor: Colors.green,
                              controlAffinity: lefthand ? ListTileControlAffinity.leading : ListTileControlAffinity.trailing,
                            ),
                            constraints: BoxConstraints(
                              maxWidth: .5 * MediaQuery.of(context).size.width,
                            ),
                          ),
                          lefthand ? Text(' Tags:   ', style: Theme.of(context).textTheme.headline3) : Container(), 
                        ]
                      ),
                      
                      Container(
                        child: (store.state.location == null || store.state.query.localTags.tags == null) ? Text('Loading Tags...') 
                                        : LocalTags(store.state.query.localTags, store.useTag), //tell it what to do when one of its chips is selected (deprecated)
                        padding: EdgeInsets.all(8),
                        margin: EdgeInsets.only(top: 12, bottom: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black54, width: 1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          lefthand ? RaisedButton(
                            child: Icon(MdiIcons.plus, semanticLabel: 'Add Tag'),
                            onPressed: (){
                              store.addTag(tagsText.text, 0);
                              Toast.show('Croaks related to "' + tagsText.text + '" will appear in your pond', context, duration: 2);
                              tagsText.clear();
                            },
                            shape: CircleBorder(),
                          ) : Container(),
                          lefthand ? Container() : Container(
                            child: TextFormField( //CUSTOM TAGS INPUT
                              controller: tagsText,
                              decoration: InputDecoration(
                                icon: Icon(Icons.category),
                                labelText: 'Add some tags of your own',
                                isDense: true,
                              ),
                              maxLines: 3,
                              minLines: 1,
                            ),
                            constraints: BoxConstraints(
                              maxWidth: .65 * MediaQuery.of(context).size.width,
                              maxHeight: MediaQuery.of(context).size.height
                            ),
                            margin: EdgeInsets.only(right: 8, left: 6),
                          ),
                          lefthand ? Container() : RaisedButton(
                            child: Icon(MdiIcons.plus, semanticLabel: 'Add Tag'),
                            onPressed: (){
                              store.addTag(tagsText.text, 0);
                              Toast.show('Croaks related to "' + tagsText.text + '" will appear in your pond', context, duration: 2);
                              tagsText.clear();
                            },
                            shape: CircleBorder(),
                          ),
                        ]
                      ),
                      /*// TODO exclude posts related to tags
                          RaisedButton(
                            child: Icon(MdiIcons.minus, semanticLabel: 'Exclude'),
                            onPressed: (){
                              store.addTag(tagsText.text, 1);
                              Toast.show('Croaks related to "' + tagsText.text + '" will not appear in your pond', context, duration: 2);
                              tagsText.clear();
                            },
                          ),
                          
                        ]
                      ),*/
                      Container(
                        child: RaisedButton(
                          child: Text('Clear Tags'),
                          onPressed: (){ 
                            store.removeLocalTags();
                            store.getSuggestedTags();
                            Toast.show("Your custom added tags have been removed", context);
                          },
                        ),
                        alignment: lefthand ? Alignment.centerLeft : Alignment.centerRight,
                        margin: EdgeInsets.only(top: 12, right: 24, left: 24)
                      ),
                      Container( //DIVIDER
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Theme.of(context).dividerColor),
                          )
                        ),
                        margin: EdgeInsets.only(top: 10, bottom: 2),
                      ),
                      Row(  //NOTIFY INTERVAL
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(' Notification Interval: ', style: Theme.of(context).textTheme.headline3),
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: .2 * MediaQuery.of(context).size.width
                            ),
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              controller: notifyIntervalTC,
                              onEditingComplete: (){
                                notifyInterval = int.parse(notifyIntervalTC.text);
                                if (notifyInterval > 15) notifyInterval = 15;
                                store.setNotificationInterval(notifyInterval);   
                                Focus.of(context).requestFocus(new FocusNode());           
                              },
                              maxLines: 1,
                              minLines: 1,
                              expands: false,
                                decoration: InputDecoration(
                                  labelText: 'Minutes',
                                  hintText: 'Minutes',
                                  contentPadding: EdgeInsets.all(0),
                                  isDense: true,
                                ),
                                textAlign: TextAlign.left,
                                style: Theme.of(context).textTheme.subtitle1,
                            ),
                            margin: formElemMargin
                          ),
                        ]
                      ),
                      Container(
                        child: RaisedButton( //UNSUB ALL
                          child: Text('UnSubscribe from all croaks'),
                          onPressed: (){
                            store.unsubAll();
                          },
                        ),
                        margin: EdgeInsets.only(top: 6, left: 12, right: 12),
                        alignment: lefthand ? Alignment.centerLeft : Alignment.centerRight,
                      ),
                      Container( //DIVIDER
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Theme.of(context).dividerColor),
                          )
                        ),
                        margin: EdgeInsets.only(top: 10, bottom: 2),
                      ),
                      motd != null ?
                      Container( //DEV MESSAGE
                        child: Linkify(text: motd, 
                          onOpen: (link)=>{ launch(link.url) }
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey)
                        ),
                        margin: EdgeInsets.all(6),
                        padding: EdgeInsets.all(6)
                      ) : Container(),
                    ],
                    
                  ),
                )
              ),
          ]
        ) 
      )
    );
  }

  @override
  bool get wantKeepAlive => true;

  void getMOTD(){
    api.getMOTD().then((r){
      setState(() {
        motd = r;
      });
    });
  }
}

//this screen should show a UI to set feed filter, user account pref, notifications
class SettingsScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SettingsScreenState();
  }
}