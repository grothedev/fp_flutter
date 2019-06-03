import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    print('constructing croakfeed: ' + this.croaksJSON.toString());
  }

  @override
  Widget build(BuildContext context) {
    if (croaksJSON == null){
      return new Container(
        child: Text('No Croaks Found'),
      );
    }
    return ListView.builder(
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

class TagChip extends StatefulWidget{

  final String label;
  final SharedPreferences prefs;

  TagChip({Key key, this.label, this.prefs}): super(key: key);

  @override
  State<StatefulWidget> createState(){
    return TagChipState();
  }
}

class TagChipState extends State<TagChip>{

  bool sel = false;

  @override
  Widget build(BuildContext context) {
      return FilterChip(
        label: Text(widget.label),
        selected: sel,
        padding: EdgeInsets.all(4),
        labelPadding: EdgeInsets.all(2),
        onSelected: ((v){
          setState((){
            sel = v;
          });
          List tl = widget.prefs.getStringList('tags');
          if (v) tl.add(widget.label);
          else tl.remove(widget.label);
          widget.prefs.setStringList('tags', tl); //i'll leave this like this for now, since it works, but it should be delegated to util
        }),
      );
  }
  
}

class SuggestedTags extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return SuggestedTagsState();
  }
}

class SuggestedTagsState extends State<SuggestedTags> with AutomaticKeepAliveClientMixin<SuggestedTags>{
  List chips; //TODO combine selected and these within one data structure? 
  int n = 10; //# tags to retreive
  bool loading = true;
  SharedPreferences prefs;
  
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p){
      this.prefs = p;
    });
    chips = <Widget>[];
    api.getTags(10).then((r){
      for (var i = 0; i < r.length; i++){
        chips.add(TagChip(label: r[i]['label'], prefs: prefs));  
      }
      setState((){
        loading = false;
        prefs.setStringList('tags', []);
      });
    });    
  }

  @override
  Widget build(BuildContext context) {
    if (this.loading){
      return Text('loading');
    } else {
      return Wrap(
        children: this.chips,
        spacing: 8  
      );
    }
  }

  @override
  bool get wantKeepAlive => true;
  
}