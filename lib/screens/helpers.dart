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
    Map c = croaksJSON[i];
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
        leading: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              child: Text( c['replies'].toString(), ),
              padding: EdgeInsets.all(6),
              alignment: Alignment.center,
              constraints: BoxConstraints(
                maxWidth: .03*MediaQuery.of(context).size.width,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey, width: 1, style: BorderStyle.solid,
                ),
                shape: BoxShape.circle
              ),
              
            ),
          ], 
        ),
        title: RichText(
          
          text: TextSpan( 
            
            text: c['content'],
            style: TextStyle(color: Colors.black),
          ),
          maxLines: 2,
          overflow: TextOverflow.fade,
          
        ),
        trailing: Column(
          
          crossAxisAlignment: CrossAxisAlignment.start,
          //mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RaisedButton( padding: EdgeInsets.all(2), key: new UniqueKey(), 
              onPressed: (){fav(i);},  
              child: favs[i] ? Icon(Icons.favorite) : Icon(Icons.favorite_border) 
            ), 
            //Text(c['score'].toString(), textAlign: TextAlign.center,)
          ],
          
        ),
        subtitle: Row(
          children: <Widget>[
            c.containsKey('distance') ? 
                              Text(c['created_at'] + ', ' + c['distance'].toInt().toString() + ' km')
                              : Text(c['created_at']),
            Spacer(
              flex: 2
            ),
            c['p_id'] == null ? //only show tags for root feed
            ConstrainedBox(constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .3), child: Text(tags.join(', '), textAlign: TextAlign.right,)) :
            Container()
          
          ]
        ),
        onTap: (){
          Navigator.push(this.context, MaterialPageRoute(
            builder: (context) => CroakDetailScreen(c)
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
                        /*validator: (value){
                            if (value.isEmpty) return 'Enter some text';
                        },*/
                        decoration: InputDecoration(
                          icon: Icon(Icons.message),
                          labelText: 'Reply',

                        ),
                        maxLines: 3,
                        minLines: 1,
                        autofocus: false,
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
  final Function onSelected;

  TagChip({Key key, this.label, this.prefs, this.onSelected}): super(key: key);

  @override
  State<StatefulWidget> createState(){
    return TagChipState();
  }
}


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
          widget.onSelected(widget.label, sel);
          
          /*if (sel){
            store.addTag(widget.label); //TODO make this only add to a set of tags which SuggestedTags widget has, with no further meaning, and parent widget can listen for sugtag selected tags change
          } else {
            store.removeTag(widget.label);
          }
          */

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
  final Function onChipSelected;

  SuggestedTags(this.location, this.onChipSelected);

  @override
  State<StatefulWidget> createState() {
    return SuggestedTagsState(location);
  }
}

class SuggestedTagsState extends State<SuggestedTags> with AutomaticKeepAliveClientMixin<SuggestedTags>{
  List chips;
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
      if (mounted){
        setState((){ 
          tags = r;
          loading = false;
          //prefs.setStringList('tags', []);

        });
      }
    });    
  }

  @override
  Widget build(BuildContext context) {
    if (this.loading){
      return Text('loading');
    } else {
      if (chips.length == 0){
        for (var i = 0; i < tags.length; i++){
          chips.add(TagChip(label: tags[i]['label'], prefs: prefs, onSelected: widget.onChipSelected));  
        }
      }
      
      return Flex(
        direction: Axis.vertical,
        children: [
          Text('Popular Tags', style: Theme.of(context).textTheme.subtitle,),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              children: this.chips,
              spacing: 8,
            ),
          )
        ]
      );
    }
  }

  @override
  bool get wantKeepAlive => true;
  
}

//my custom appbar/title to go under the app title on each screen
//currently unused since i decided to get rid of global app title. still might switch to using global app title with screen subtitles
//it is easier to deal with screen-specific actions without the global title
class ScreenTitle extends StatelessWidget implements PreferredSizeWidget{

  final String label;
  final Size size = Size.fromHeight(20);

  ScreenTitle(this.label);
  
  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      child: Text(
        label,
        style: Theme.of(context).textTheme.headline,
      ),
      preferredSize: size,
    );
  }

  @override
  Size get preferredSize => size;

}
