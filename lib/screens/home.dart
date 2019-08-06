import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fp/main.dart';
import 'package:fp/screens/helpers.dart';
import 'package:fp/state_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../consts.dart';

class HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin<HomeScreen>{
  
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
      setState((){
        if (store.state.lat == null || store.state.lon == null){
          //store.getLocation();
          locStr = 'Getting Location...';
        } else locStr = 'Your Location: ' + store.state.lat.toString() + ', ' + store.state.lon.toString();
        
      });
      
    });
    /*tagsText.addListener((){
      List tagsFromText = tagsText.text.split(' ');
      List tl = prefs.getStringList('tags');
      for (String t in tagsFromText){ //TODO this does not account for deleting tags
        if (!tl.contains(t)){
          tl.add(t);
        }
      }
      prefs.setStringList('tags', tl);
    });
    */
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
      //appBar: ScreenTitle('Welcome to FrogPond'),
      appBar: AppBar(
        title: Text('Frog Pond'),
      ),
      body:  SingleChildScrollView(
        
        child: Column(
          children: [
            Container(
              child: Text('Welcome to the pond',
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
                      
                      Container(
                        child: TextFormField( //TAGS INPUT
                          controller: tagsText,
                          decoration: InputDecoration(
                            icon: Icon(Icons.category),
                            labelText: 'Tags'
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
                        margin: formElemMargin,
                        child: (store.state.location == null) ? Text('Waiting for location...') 
                                        : SuggestedTags(store.state.location, updateQueryTags), //tell it what to do when one of its chips is selected
                      ),
                      //phase 2: keywords
                      /*
                      TextFormField( //KEYWORDS INPUT
                        controller: tagsText,
                        decoration: InputDecoration(
                          icon: Icon(Icons.message),
                          labelText: 'Keywords'
                        ),
                        maxLines: 3,
                        minLines: 1,
                      ),
                      */
                      Container(
                        child: CheckboxListTile(
                          title: Text('Search for croaks with all (on) or some (off) of these tags?'),
                          value: kwdAll,
                          onChanged: (v){
                            setState((){
                              SharedPreferences.getInstance().then((pref){
                                pref.setBool("query_all", v);
                              });
                              kwdAll = v;
                            });
                            store.toggleExclusive();
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
                            ),
                            margin: formElemMargin
                          ),
                          Text('km')
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

                      )
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
}

//this screen should show a UI to set feed filter, user account pref, notifications
class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomeScreenState();
  }


}