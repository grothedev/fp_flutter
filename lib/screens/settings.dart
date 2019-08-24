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
along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
*/

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fp/main.dart';
import 'package:fp/models.dart';
import 'package:fp/state_container.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:toast/toast.dart';

import '../consts.dart';
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
                onPressed: ()=>launch('http://' + api.host + ':8090/about'),

              ),
              duration: Duration(seconds: 8),
              //animation: (),
               
          )
        );
      }
      /*
      setState((){
        if (store.state.lat == null || store.state.lon == null){
          //store.getLocation();
          locStr = 'Getting Location...';
        } else locStr = 'Your Location: ' + store.state.lat.toString() + ', ' + store.state.lon.toString();
        
      });
      */
      
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
    if (store.state.lat == null || store.state.lon == null){
      //store.getLocation();
      store.getLocation();
      locStr = 'Getting Location...';
    
    } else locStr = 'Your Location: ' + store.state.lat.toString() + ', ' + store.state.lon.toString();
    
    if (store.state.query.localTags.tags == null || store.state.query.localTags.tags.isEmpty){
      store.getSuggestedTags();
    }

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
        ]
      ),
      body:  SingleChildScrollView(
        child: Column(
          children: [
            Form(
              key: fk,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                
                  child: Column(

                    children: [
                      Text(
                        'Here are some options to refine your search query',
                        style: Theme.of(context).textTheme.title
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Search Radius '),
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: .2 * MediaQuery.of(context).size.width
                            ),
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              controller: radText,
                              onEditingComplete: (){
                                radius = double.parse(radText.text);
                                print('got rad ' + radius.toString());
                                SharedPreferences.getInstance().then((pref){
                                  pref.setInt('radius', radius.toInt());
                                });
                                store.setRadius(radius.toInt());              
                              },
                              decoration: InputDecoration(
                                labelText: 'Radius',  
                              ),
                              maxLines: 1,
                              minLines: 1,
                              expands: false,
                              //initialValue: '0 = infinity',
                            ),
                            margin: formElemMargin
                          ),
                          Text('km'),
                        ]
                      ),
                      Container(
                        padding: EdgeInsets.all(8)
                      ),
                      /* should the slider be used?
                      Expanded(
                        child: Slider(
                          onChanged: (v){
                            double r = v;
                            setState(() {
                              radius = r;
                              radText.text = radius.toString();
                              SharedPreferences.getInstance().then((pref){
                                pref.setInt('radius', r.toInt());
                              });
                              store.setRadius(r.toInt());
                              radiusSlider = v;
                            });
                          },
                          label: 'Distance',
                          value: radiusSlider,
                          min: 2,
                          max: 100,
                          divisions: 40,
                          
                        ),
                      ),
                      */
                      Text('Popular Tags: '),
                      Container(
                        margin: formElemMargin,
                        child: (store.state.location == null || store.state.query.localTags.tags == null) ? Text('Loading Tags...') 
                                        : LocalTags(store.state.query.localTags, null), //tell it what to do when one of its chips is selected (deprecated)
                      ),
                      
                      TextFormField( //TAGS INPUT
                        controller: tagsText,
                        decoration: InputDecoration(
                          icon: Icon(Icons.category),
                          labelText: 'Add some tags of your own'
                        ),
                        maxLines: 3,
                        minLines: 1,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RaisedButton(
                            child: Icon(MdiIcons.plus, semanticLabel: 'Add Tag'),
                            onPressed: (){
                              store.addTag(tagsText.text, 0);
                              Toast.show('Croaks related to "' + tagsText.text + '" will appear in your pond', context, duration: 2);
                              tagsText.clear();
                            },
                          ),
                          /* TODO exclude posts related to tags
                          RaisedButton(
                            child: Icon(MdiIcons.minus, semanticLabel: 'Exclude'),
                            onPressed: (){
                              store.addTag(tagsText.text, 1);
                              Toast.show('Croaks related to "' + tagsText.text + '" will not appear in your pond', context, duration: 2);
                              tagsText.clear();
                            },
                          ),
                          */
                        ]
                      ),
                      CheckboxListTile(
                        title: Text('See croaks with all (on) or some (off) of these tags?'),
                        dense: true,
                        value: store.state.query.tagsIncludeAll,
                        onChanged: (v){
                          store.tagsIncludeAll(v);
                        },
                        activeColor: Colors.green,
                        
                      ),
                      /* location feedback was used for debugging
                      Container(
                        child: (locStr == null) ? Text('Getting location...') : Text(locStr),
                        margin: EdgeInsets.only(bottom: 2),
                        padding: EdgeInsets.only(left: 8),
                      ),
                      */
                      RaisedButton(
                        child: Text('Remove Your Tags'),
                        onPressed: (){ 
                          store.removeLocalTags();
                          store.getSuggestedTags();
                        },
                      ),
                      Container( //DIVIDER
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Theme.of(context).dividerColor),
                          )
                        ),
                        margin: EdgeInsets.only(top: 10, bottom: 2),
                      ),
                      Container( //DEV MESSAGE
                        child: Linkify(text: motd),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey)
                        ),
                        margin: EdgeInsets.all(6),
                        padding: EdgeInsets.all(6)
                      ),
                      Container( //DIVIDER
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Theme.of(context).dividerColor),
                          )
                        ),
                        margin: EdgeInsets.only(top: 10, bottom: 2),
                      ),
                      Row(
                        children: [
                          Text('Notification interval: '),
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: .2 * MediaQuery.of(context).size.width
                            ),
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              controller: notifyIntervalTC,
                              onEditingComplete: (){
                                notifyInterval = int.parse(notifyIntervalTC.text);
                                SharedPreferences.getInstance().then((pref){
                                  pref.setInt('notify_check_interval', notifyInterval);
                                });
                                store.setNotificationInterval(notifyInterval);   
                                Focus.of(context).requestFocus(new FocusNode());           
                              },
                              decoration: InputDecoration(
                                labelText: 'minutes',  
                              ),
                              maxLines: 1,
                              minLines: 1,
                              expands: false,
                            ),
                            margin: formElemMargin
                          ),
                        ]
                      )
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

  void notifyTest(){
    
  }

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