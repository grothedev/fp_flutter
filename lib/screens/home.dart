import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fp/screens/helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';


class HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin<HomeScreen>{
  
  TextEditingController dbgTC;
  final fk = GlobalKey<FormState>();
  TextEditingController tagsText = TextEditingController();
  bool kwdAll = false;

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to FrogPond')
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
                    TextFormField( //TAGS INPUT
                      controller: tagsText,
                      decoration: InputDecoration(
                        icon: Icon(Icons.category),
                        labelText: 'Tags'
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                    SuggestedTags(),
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
                    CheckboxListTile(
                      title: Text('All (on) or Some (off):'),
                      value: kwdAll,
                      onChanged: (v){
                        setState((){
                          SharedPreferences.getInstance().then((pref){
                            pref.setBool("query_kwdAll", v);
                          });
                          kwdAll = v;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                    
                    Container(
                      child: Text('Location Data: ', //TODO include actual data
                      
                      ),
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
  
}

//this screen should show a UI to set feed filter, user account pref, notifications
class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomeScreenState();
  }


}