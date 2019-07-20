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
  bool kwdAll = false;
  List tags;
  SharedPreferences prefs;
  String locStr;
  StateContainerState store;
  double radius = 30;
  int distUnit = KM;

  EdgeInsets formPadding = EdgeInsets.all(6.0);
  EdgeInsets formElemMargin = EdgeInsets.all(8.0);

  initState(){
    SharedPreferences.getInstance().then((p){
      this.prefs = p;
      setState((){
        if (store.state.location == null){
          store.getLocation();
          locStr = 'Getting Location...';
        } else 
        locStr = 'Location Data: ' + store.state.location.latitude.toString() + ', ' + store.state.location.longitude.toString();
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
    return Scaffold(
      //appBar: ScreenTitle('Welcome to FrogPond'),
      appBar: AppBar(
        title: Text('Frog Pond'),
      ),
      body:  SingleChildScrollView(
        
        child: Column(
          children: [
            Container(
              child: Text('Welcome to the pond, young tadpole! Come grow some legs and croak with your frog breathren. \n Configure your search query and preferences on this screen. Swipe right to go for a swim or croak your own croak.',
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
                    Container(
                      margin: formElemMargin,
                      child: SuggestedTags(store.state.location, updateQueryTags), //tell it what to do when one of its chips is selected
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
                        title: Text('All (on) or Some (off):'),
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
                      margin: formElemMargin
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 5, right: 8),
                      child: Row( 
                        children: <Widget>[
                          Text(
                            distUnit == KM ? 'Radius: ' +  radius.toInt().toString() + ' km '
                                          : 'Radius: ' + (radius * .621).toInt().toString() + ' mi ' ,
                          ),
                          Expanded(
                            child: Slider(
                              onChanged: (v){
                                double r = v;
                                if (distUnit == MI){
                                  r = 1.609344 * v;
                                }
                                setState(() {
                                  radius = r;
                                  SharedPreferences.getInstance().then((pref){
                                    pref.setInt('radius', r.toInt());
                                  });
                                  store.setRadius(r.toInt());
                                });
                              },
                              label: 'Distance',
                              value: radius,
                              min: 2,
                              max: 100,
                              divisions: 40,
                              
                            ),
                          ),
                          DropdownButton(
                            items: [
                              DropdownMenuItem<int>(
                                child: Text('km'),
                                value: KM
                              ),
                              DropdownMenuItem<int>(
                                child: Text('Mi'),
                                value: MI
                              ),
                            ],
                            onChanged: (u){
                              setState(() {
                                distUnit = u;                              
                              });
                              SharedPreferences.getInstance().then((pref){
                                pref.setInt('dist_unit', distUnit);
                              });
                              store.setDistUnit(u);
                            },
                            value: distUnit,
                          )
                        ],
                      ),
                    ),
                    Container(
                      child: (locStr == null) ? Text('Getting location...') : Text(locStr),
                      margin: EdgeInsets.only(bottom: 2),
                      padding: EdgeInsets.only(left: 8),

                    )
                  ],
                  
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