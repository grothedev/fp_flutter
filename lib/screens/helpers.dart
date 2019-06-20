import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fp/state_container.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import '../util.dart' as util;
import 'croakdetail.dart';
import '../api.dart' as api;

//things that are not full screens, like widgets and dialogs

class CroakFeed extends StatefulWidget{
  //final int pid; //don't think this is needed anymore
  final List croaksJSON;

  CroakFeed(this.croaksJSON);

  @override
  State<StatefulWidget> createState() {
    return CroakFeedState(croaksJSON);
  }
}

class CroakFeedState extends State<CroakFeed>{
  int pid;
  List croaksJSON; //json array
  List<bool> favs;
  StateContainerState store;

  CroakFeedState(this.croaksJSON){
    favs = new List<bool>();
  }

  @override
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

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

    favs.add(false);

    return new Container(
      padding: EdgeInsets.only(left: 6, right: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: .2,
        ),
      ),
      child: ListTile(
        dense: false,
        
        title: RichText(
          
          text: TextSpan( 
            
            text: croaksJSON[i]['content'],
            style: TextStyle(color: Colors.black),
          ),
          maxLines: 2,
          overflow: TextOverflow.fade,
          
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
            Text(croaksJSON[i]['created_at']),
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
          Navigator.push(this.context, MaterialPageRoute(
            builder: (context) => FeedItemOptionsDialog()
          ));
        }),
      )
      );
  }

  //toggles "favorite" or normal for a croak  
  void fav(int id){
    setState((){
      favs[id] = !favs[id];
    });
  }

}

//pop-up of list of actions when long press a croak on the feed
class FeedItemOptionsDialog extends Dialog{
  @override
  Widget build(BuildContext context){

  }
}

/*
  * probably obsolete. just including it on bottom of croakdetail screen
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
              contentPadding: EdgeInsets.all(6),
              titlePadding: EdgeInsets.all(4),
              title: (this.parent != null) ? Text('Reply') : Text('Croak'),
              children: [
                Form(
                  key: fk,
                  child: Column(
                    //direction: Axis.vertical,
                    children: [
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
                        //autofocus: true,
                        autovalidate: false,
                        
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
                              //Scaffold.of(context).showSnackBar(SnackBar(content: Text('Replying...')));
                              Croak r = Croak();
                              util.submitReply(parent['pid'], contentController.text, parent['tags'], true); //TODO add functionality to add additional tags?
                            }
                          },
                          child: Text("Reply"),

                        )
                    ]
                  ),
                ),
                
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)), 
              ),
              

            ) ;
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


//TODO figure out the best way to send tags to feedscreen and to notify screen that tags have been updated. react/redux automatically deals with this
class TagChipState extends State<TagChip>{

  bool sel = false;
  StateContainerState store; //i think this is pretty close to the redux concept of a "store". thought var name "stateContainer was too long"

  @override
  Widget build(BuildContext context) {
      store = StateContainer.of(context);
      
      return FilterChip(
        label: Text(widget.label),
        selected: sel,
        padding: EdgeInsets.all(4),
        labelPadding: EdgeInsets.all(2),
        onSelected: ((v){
          setState((){
            sel = v;
          });
          if (sel){
            store.addTag(widget.label);
          } else {
            store.removeTag(widget.label);
          }
          //store.needsUpdate();

          //List tl = widget.prefs.getStringList('tags');
          //if (v) tl.add(widget.label);
          //else tl.remove(widget.label);
          //widget.prefs.setStringList('tags', tl); //i'll leave this like this for now, since it works, but it should be delegated to util
         //print('tag chip updated: ' + widget.prefs.getStringList('tags').toString());
          //widget.prefs.setBool('needsUpdate', true);
        }),
      );
  }
  
}

class SuggestedTags extends StatefulWidget{
  final LocationData location;

  SuggestedTags(this.location);

  @override
  State<StatefulWidget> createState() {
    return SuggestedTagsState(location);
  }
}

class SuggestedTagsState extends State<SuggestedTags> with AutomaticKeepAliveClientMixin<SuggestedTags>{
  List chips; //TODO combine selected and these within one data structure? 
  int n = 10; //# tags to retreive
  bool loading = true;
  SharedPreferences prefs;
  List tags; //suggested tags retrieved from server
  LocationData location;

  SuggestedTagsState(this.location);

  @override
  void initState() {
    super.initState();

    chips = <Widget>[];
    util.getTags(10, location).then((r){
      setState((){ 
        tags = r;
        loading = false;
        //prefs.setStringList('tags', []);

      });
    });    
  }

  @override
  Widget build(BuildContext context) {
    if (this.loading){
      return Text('loading');
    } else {
      if (chips.length == 0){
        for (var i = 0; i < tags.length; i++){
          chips.add(TagChip(label: tags[i]['label'], prefs: prefs));  
        }
      }
      
      return Wrap(
        children: this.chips,
        spacing: 8  
      );
    }
  }

  @override
  bool get wantKeepAlive => true;
  
}