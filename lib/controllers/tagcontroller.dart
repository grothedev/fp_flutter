import 'package:FrogPond/controllers/controller.dart';
import 'package:FrogPond/models/tagstore.dart';
import 'package:FrogPond/api.dart' as api;
import 'package:flutter/foundation.dart';

class TagController extends Controller {
  LocalTagsStore tagStore;

  TagController(){
    tagStore = state.query.localTags; 
  }


  void getSuggestedTags() async {
    List tags;
    if (state.location==null) {
      tags = await api.getTags(8, null, null);
    } else {
      tags = await api.getTags(8, state.location.latitude, state.location.longitude);
    }
    List<String> tagLbls = tags.map((t){ return t['label'].toString(); }).toList();
    tagStore.add(tagLbls, false);  
    prefs.setString('local_tags', tagStore.toJSON());
  }

  /**
   * add tag to the local tag-store with the given mode
   */
  void addTag(String t, int mode){
    tagStore.add(t, true);
    tagStore.set(t, mode); 
    state.feedOutdated = true;
  
    prefs.setString('local_tags', tagStore.toJSON());
    prefs.setBool('feed_outdated', true);
  }

  //empty the local tag-store
  void removeLocalTags(){
    tagStore.empty();
    state.feedOutdated = true;
  
    prefs.setString('local_tags', tagStore.toJSON());
  }

  //set tag query type
  void setExclusive(bool e){
    state.query.tagsIncludeAll = e;
    state.feedOutdated = true;
    //prefs.setString('local_tags', state.query.localTags.toJSON());
    prefs.setBool('feed_outdated', true);
  }

  //set whether or not this tag shall be used for the query
  void useTag(String label, bool u){
    tagStore.use(label, u); 
    state.feedOutdated = true;
    
    prefs.setString('local_tags', tagStore.toJSON());
  }
}