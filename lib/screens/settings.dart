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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fp/main.dart';
import 'package:fp/screens/helpers.dart';
import 'package:fp/state_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../consts.dart';
import '../api.dart' as api;

class SettingsScreenState extends State<SettingsScreen> with AutomaticKeepAliveClientMixin<SettingsScreen>{
  
  TextEditingController dbgTC;
  final fk = GlobalKey<FormState>();
  TextEditingController tagsText = TextEditingController();
  TextEditingController radText = TextEditingController();
  bool kwdAll = false;
  List tags;
  SharedPreferences prefs;
  String locStr;
  StateContainerState store;
  double radius;
  double radiusSlider = 30; //used just for the slider UI component
  
  EdgeInsets formPadding = EdgeInsets.all(6.0);
  EdgeInsets formElemMargin = EdgeInsets.all(8.0);

  initState(){
    SharedPreferences.getInstance().then((p){
      this.prefs = p;
      if (prefs.getBool('firstrun') == null || prefs.getBool('firstrun')){
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
        prefs.setBool('firstrun', false);
      }
      setState((){
        if (store.state.lat == null || store.state.lon == null){
          //store.getLocation();
          locStr = 'Getting Location...';
        } else locStr = 'Your Location: ' + store.state.lat.toString() + ', ' + store.state.lon.toString();
        
      });
      
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Frog Pond'),
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
            Container(
              child: Text('Adjust your settings here',
                style: Theme.of(context).textTheme.headline,
                maxLines: 5,
                overflow: TextOverflow.visible,
              ),
              //constraints: BoxConstraints(maxHeight: 20),
              padding: EdgeInsets.all(10),
            ),
            Form(
              key: fk,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Center(
                  child: Column(
                    children: [
                      Text('Here are some popular tags in your area; tap them to include them in your query'),
                      Container(
                        margin: formElemMargin,
                        child: (store.state.location == null) ? Text('Waiting for location...') 
                                        : SuggestedTags(store.state.location, updateQueryTags), //tell it what to do when one of its chips is selected
                      ),
                      Container(
                        child: TextFormField( //TAGS INPUT
                          controller: tagsText,
                          decoration: InputDecoration(
                            icon: Icon(Icons.category),
                            labelText: 'Tags of your own: '
                          ),
                          maxLines: 3,
                          minLines: 1,
                        ),
                        margin: formElemMargin
                      ),
                      Text('Tags must be seperated by spaces, and cannot contain spaces or special characters',
                        style: Theme.of(context).textTheme.caption
                      ),
                      Container(
                        child: CheckboxListTile(
                          title: Text('Search for croaks with all (on) or some (off) of these tags?'),
                          value: store.state.query.tags_include_all,
                          onChanged: (v){
                            store.tagsIncludeAll(v);
                          },
                          activeColor: Colors.green,
                        ),
                        //margin: formElemMargin,
                        width: MediaQuery.of(context).size.width * .7
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Search for croaks within '),
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
                                icon: Icon(Icons.directions),
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
                        padding: EdgeInsets.only(left: 5, right: 8),
                        child: Row( 
                          children: <Widget>[
                            
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
                            
                          ],
                        ),
                      ),
                      Container(
                        child: (locStr == null) ? Text('Getting location...') : Text(locStr),
                        margin: EdgeInsets.only(bottom: 2),
                        padding: EdgeInsets.only(left: 8),

                      ),

                      //had help here, but moved it to the app bar
                      /*
                      Container(
                        child: GestureDetector( 
                          child: Text('New? Tap here to learn.'),
                          onTap: () => launch('http://' + api.host + '/about'),
                        ),
                        margin: EdgeInsets.only(top: 40),
                        alignment: Alignment.bottomCenter,
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border: Border.all(width: .5, color: Colors.grey),
                        ),
                        )
                        */
                    ],
                    
                  ),
                )
              ),
            ),
          ]
        ) 
      )
    );
  }

  @override
  bool get wantKeepAlive => true;
  
  void updateQueryTags(String tag, bool sel){
    if (sel){
      store.addTag(tag);
    } else {
      store.removeTag(tag);
    }
  }

  void notifyTest(){
    
  }
}

//this screen should show a UI to set feed filter, user account pref, notifications
class SettingsScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SettingsScreenState();
  }


}