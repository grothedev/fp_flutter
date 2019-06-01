import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../util.dart' as util;
import 'croakdetail.dart';
import '../api.dart' as api;

//things that are not full screens, like widgets and dialogs

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
        child: Text('No Croaks Found'),
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
      dense: false,
      
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
          //mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RaisedButton( padding: EdgeInsets.all(2), key: new UniqueKey(), onPressed: (){fav(i);},  child: favs[i] ? Icon(Icons.favorite) : Icon(Icons.favorite_border) ), 
            //Text(croaksJSON[i]['score'].toString(), textAlign: TextAlign.center,)
          ],
          
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
        contentPadding: EdgeInsets.all(4),
        onLongPress: ((){

        }),
        
      );


  }

  //toggles "favorite" or normal for a croak  
  void fav(int id){
    setState((){
      favs[id] = !favs[id];
    });
  }
}

/*
//a form to overlay the main UI to make and submit croaks.
  was gonna use this for both replies and root croaks, but decided to keep ComposeDialog and ComposeScreen separate,
  because ComposeScreen may as well keep its "fuller" design
*/
class ComposeCroakDialog extends Dialog{
  
  final contentController = TextEditingController();
  final fk = GlobalKey<FormState>();// form key
  final Map parent; //croak replying to
  bool anon = true;

  ComposeCroakDialog(this.parent);

  @override
  Widget build(BuildContext context){
    return SimpleDialog( 
              contentPadding: EdgeInsets.all(12.0),
              children: [
                (this.parent != null) ? Text('Reply') : Text('Croak'),
                TextFormField(
                  controller: contentController,
                  validator: (value){
                      if (value.isEmpty) return 'Enter some text';
                    },
                    decoration: InputDecoration(
                      icon: Icon(Icons.message),
                      labelText: 'Reply',
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                  
                  //force anon for phase 1
                  /*
                  CheckboxListTile(
                    value: this.anon,
                    title: Text('anon'),
                    onChanged: (v){
                      anon = !anon;
                    },

                  ),
                  */
                  RaisedButton(
                          onPressed: (){
                            if (fk.currentState.validate()){
                              Scaffold.of(context).showSnackBar(SnackBar(content: Text('Replying...')));
                              Croak r = Croak();
                              util.submitReply(parent['pid'], contentController.text, parent['tags'], true); //TODO add functionality to add additional tags?
                            }
                          },
                          child: Text("Reply"),

                        )
              ]
            ) ;
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

class SuggestedTags extends StatelessWidget{

  List chips;
  List<bool> selTags; //bool for selected
  int n = 10; //# tags to retreive

  @override
  Widget build(BuildContext context) {

    api.getTags(10).then((r){
      for (var i = 0; i < r.length; i++){
        selTags.add(false);
        chips.add( new ChoiceChip(
          label: Text(r[i]['label']),
          selected: selTags[i],
        ));

      }
      
    });    

    return Wrap(
        children: chips
      );
  }


  
}